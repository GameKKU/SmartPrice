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
 * Makes a request to the Ark API
 */
async function makeArkApiRequest(messages) {
    try {
        console.log('Making Ark API request with messages:', JSON.stringify(messages, null, 2));
        
        const requestData = {
            model: model,
            messages: messages
        };
        
        console.log('Request data:', JSON.stringify(requestData, null, 2));
        
        const response = await axios.post(`${ARK_BASE_URL}/chat/completions`, requestData, {
            headers: {
                'Authorization': `Bearer ${ARK_API_KEY}`,
                'Content-Type': 'application/json'
            }
        });

        return {
            content: response.data.choices[0].message.content,
            usage: response.data.usage
        };
    } catch (error) {
        console.error('Ark API Error Details:');
        console.error('Status:', error.response?.status);
        console.error('Status Text:', error.response?.statusText);
        console.error('Response Data:', JSON.stringify(error.response?.data, null, 2));
        console.error('Request Config:', JSON.stringify({
            url: error.config?.url,
            method: error.config?.method,
            headers: error.config?.headers,
            data: error.config?.data
        }, null, 2));
        throw new Error(`Ark API request failed: ${error.message}`);
    }
}

/**
 * Analyzes the image using the provided LLM and returns a suggested resell price range.
 */
async function analyzeImageWithLlm(imageUrl, searchResults = null) {
    let textPrompt = "Analyze the quality of the item based on the user-provided image and the provided search results. Suggest a resell price range for the item in Thai Baht. Consider the item's condition from the image and the prices found in the search results. Provide the answer in Thai.";
    
    if (searchResults) {
        textPrompt = `Analyze the quality of the item based on the user-provided image and the following search results. Suggest a resell price range for the item in Thai Baht. Consider the item's condition from the image and the prices found in the search results. Search Results: ${JSON.stringify(searchResults)}. Provide the answer in Thai. Output: คุณภาพของอุปกรณ์ และ สรุปคำแนะนำราคามือสอง`;
    }

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
    res.json({ status: 'OK', message: 'Smart Price Checker API is running' });
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

        // Step 1: Generate search keyword using LLM
        const keywordMessages = [{
            role: "user",
            content: [
                { type: "image_url", image_url: { url: imageUrl } },
                { type: "text", text: "Based on this image, identify the main item, its series, and year of production. Only output the item, series, and year, nothing else." }
            ]
        }];

        const keywordResult = await makeArkApiRequest(keywordMessages);
        const itemInfo = keywordResult.content.trim();

        // Step 2: Perform SerpAPI search
        const searchQuery = `${itemInfo} ราคา มือสอง`;
        const searchResults = await performSerpApiSearch(searchQuery);

        // Step 3: Final analysis with LLM
        const analysisResult = await analyzeImageWithLlm(imageUrl, searchResults);

        // Return comprehensive response
        res.json({
            success: true,
            data: {
                imageUrl: imageUrl,
                identifiedItem: itemInfo,
                searchQuery: searchQuery,
                searchResults: searchResults.map(result => ({
                    title: result.title || 'No title',
                    link: result.link || 'No link',
                    snippet: result.snippet || ''
                })),
                analysis: analysisResult.content,
                tokenUsage: {
                    keyword: keywordResult.usage,
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
    console.log(`Smart Price Checker API server running on port ${PORT}`);
    console.log(`Health check: http://localhost:${PORT}/health`);
    console.log(`Android emulator health check: http://10.0.2.2:${PORT}/health`);
    console.log(`Main endpoint: POST http://localhost:${PORT}/analyze-price`);
});

module.exports = app;