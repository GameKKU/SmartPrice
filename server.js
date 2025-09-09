const express = require('express');
const cors = require('cors');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 3000;

// Configuration
const model = "ep-20250731234418-8kgvb";
const ARK_API_KEY = "f384354f-c1c5-4705-a96a-9013ae1dcaa2";
const SERPAPI_API_KEY = "088ca307d157c6e3a613c93763208773428aac757e5f43837155221fbc20e55a";
const ARK_BASE_URL = "https://ark.ap-southeast.bytepluses.com/api/v3";

// Test with a simpler model name if the current one fails
const FALLBACK_MODEL = "gpt-4-vision-preview";

// Middleware
app.use(cors());
app.use(express.json());

// Utility function to validate URL
function isValidUrl(string) {
    try {
        new URL(string);
        return string.startsWith('http://') || string.startsWith('https://');
    } catch (_) {
        return false;
    }
}

/**
 * Performs SerpAPI search with the given query
 */
async function performSerpApiSearch(query) {
    if (!SERPAPI_API_KEY) {
        throw new Error('SERPAPI_API_KEY not configured');
    }

    const params = {
        engine: 'google',
        q: query,
        api_key: SERPAPI_API_KEY
    };

    try {
        const response = await axios.get('https://serpapi.com/search', { params });
        const organicResults = response.data.organic_results || [];
        return organicResults;
    } catch (error) {
        throw new Error(`SerpAPI search failed: ${error.message}`);
    }
}

/**
 * Makes a request to the Ark API with retry logic
 */
async function makeArkApiRequest(messages, retries = 2) {
    for (let attempt = 1; attempt <= retries + 1; attempt++) {
        try {
            console.log(`Making Ark API request (attempt ${attempt}/${retries + 1})`);
            
            // Try with the primary model first, then fallback
            const modelToUse = attempt === 1 ? model : FALLBACK_MODEL;
            
            const requestData = {
                model: modelToUse,
                messages: messages,
                max_tokens: 1000,
                temperature: 0.1
            };
            
            console.log(`Using model: ${modelToUse}`);
            
            const response = await axios.post(`${ARK_BASE_URL}/chat/completions`, requestData, {
                headers: {
                    'Authorization': `Bearer ${ARK_API_KEY}`,
                    'Content-Type': 'application/json'
                },
                timeout: 60000 // 60 seconds timeout
            });

            return {
                content: response.data.choices[0].message.content,
                usage: response.data.usage
            };
        } catch (error) {
            console.error(`Ark API Error (attempt ${attempt}):`);
            console.error('Status:', error.response?.status);
            console.error('Status Text:', error.response?.statusText);
            console.error('Error Message:', error.message);
            console.error('Response Data:', error.response?.data);
            console.error('Request Data:', JSON.stringify(requestData, null, 2));
            
            if (attempt === retries + 1) {
                // Last attempt failed
                throw new Error(`Ark API request failed after ${retries + 1} attempts: ${error.message}`);
            }
            
            // Wait before retry (exponential backoff)
            const waitTime = Math.pow(2, attempt - 1) * 1000; // 1s, 2s, 4s...
            console.log(`Waiting ${waitTime}ms before retry...`);
            await new Promise(resolve => setTimeout(resolve, waitTime));
        }
    }
}

/**
 * Validates if the image URL is accessible and in a supported format
 */
async function validateImageUrl(imageUrl) {
    try {
        // Check if URL is accessible
        const response = await axios.head(imageUrl, { timeout: 10000 });
        const contentType = response.headers['content-type'];
        
        // Check if it's an image
        if (!contentType || !contentType.startsWith('image/')) {
            throw new Error(`Invalid content type: ${contentType}`);
        }
        
        console.log(`Image URL validated: ${contentType}`);
        return true;
    } catch (error) {
        console.error(`Image URL validation failed: ${error.message}`);
        return false;
    }
}

/**
 * Analyzes the image using the provided LLM and returns a suggested resell price range.
 */
async function analyzeImageWithLlm(imageUrl, searchResults = null) {
    // Validate image URL first
    const isValidImage = await validateImageUrl(imageUrl);
    if (!isValidImage) {
        throw new Error('Invalid or inaccessible image URL');
    }
    
    const textPrompt = `Analyze the quality of the item from the user-provided image and the following search results. Identify the name of the item, provide a quality rating from 0 to 5 stars, and suggest a resell price range in Thai Baht. Respond with a JSON object containing four keys: "item_name" (the name of the item), "rating_stars" (a number from 0 to 5), "min_price_thb" (minimum suggested price), and "max_price_thb" (maximum suggested price). Do not include any additional text or explanations. Search Results: ${JSON.stringify(searchResults || [])}`;

    const messages = [{
        role: "user",
        content: [
            { type: "image_url", image_url: { url: imageUrl } },
            { type: "text", text: textPrompt }
        ]
    }];

    return await makeArkApiRequest(messages);
}

// API Routes

/**
 * Health check endpoint
 */
app.get('/health', (req, res) => {
    res.json({ status: 'OK', message: 'Barter Gang API is running' });
});

/**
 * Main endpoint to analyze image and get price estimation
 */
app.post('/analyze-price', async (req, res) => {
    try {
        const { imageUrl } = req.body;

        // Validate input
        if (!imageUrl) {
            return res.status(400).json({
                error: 'Image URL is required',
                message: 'Please provide an imageUrl in the request body'
            });
        }

        if (!isValidUrl(imageUrl)) {
            return res.status(400).json({
                error: 'Invalid URL format',
                message: 'Please provide a valid HTTP or HTTPS URL'
            });
        }

        // Step 1: Perform SerpAPI search with a general keyword
        console.log('Performing SerpAPI search...');
        const searchQuery = `secondhand price มือสอง`;
        const searchResults = await performSerpApiSearch(searchQuery);
        
        console.log('SerpAPI Search Results:');
        searchResults.forEach(result => {
            console.log(`- ${result.title || 'No title'} - ${result.link || 'No link'}`);
        });

        // Step 2: LLM analyzes image and search results to provide structured rating and price
        console.log('LLM analyzing image for structured rating and price...');
        
        const analysisResult = await analyzeImageWithLlm(imageUrl, searchResults);
        
        // Parse JSON response from LLM
        let parsedAnalysis;
        try {
            parsedAnalysis = JSON.parse(analysisResult.content);
        } catch (error) {
            console.error('Failed to parse LLM response as JSON:', error);
            parsedAnalysis = {
                item_name: "Unknown Item",
                rating_stars: 3,
                min_price_thb: 100,
                max_price_thb: 500
            };
        }

        // Return comprehensive response
        res.json({
            success: true,
            data: {
                imageUrl: imageUrl,
                searchQuery: searchQuery,
                searchResults: searchResults.map(result => ({
                    title: result.title || 'No title',
                    link: result.link || 'No link',
                    snippet: result.snippet || ''
                })),
                analysis: parsedAnalysis,
                tokenUsage: {
                    analysis: analysisResult.usage
                }
            }
        });

    } catch (error) {
        console.error('Error in /analyze-price:', error.message);
        res.status(500).json({
            error: 'Internal server error',
            message: error.message
        });
    }
});

/**
 * Endpoint to just identify item from image
 */
app.post('/identify-item', async (req, res) => {
    try {
        const { imageUrl } = req.body;

        if (!imageUrl || !isValidUrl(imageUrl)) {
            return res.status(400).json({
                error: 'Valid image URL is required'
            });
        }

        const keywordMessages = [{
            role: "user",
            content: [
                { type: "image_url", image_url: { url: imageUrl } },
                { type: "text", text: "Based on this image, identify the main item, its series, and year of production. Only output the item, series, and year, nothing else." }
            ]
        }];

        const result = await makeArkApiRequest(keywordMessages);
        
        res.json({
            success: true,
            data: {
                imageUrl: imageUrl,
                identifiedItem: result.content.trim(),
                tokenUsage: result.usage
            }
        });

    } catch (error) {
        console.error('Error in /identify-item:', error.message);
        res.status(500).json({
            error: 'Internal server error',
            message: error.message
        });
    }
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Unhandled error:', err);
    res.status(500).json({
        error: 'Internal server error',
        message: 'Something went wrong'
    });
});

// 404 handler
app.use('*', (req, res) => {
    res.status(404).json({
        error: 'Not found',
        message: 'The requested endpoint does not exist'
    });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Barter Gang API server running on port ${PORT}`);
    console.log(`Health check: http://localhost:${PORT}/health`);
    console.log(`Android emulator health check: http://10.0.2.2:${PORT}/health`);
    console.log(`Main endpoint: POST http://localhost:${PORT}/analyze-price`);
});

module.exports = app;