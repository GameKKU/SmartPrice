const readline = require('readline');
const axios = require('axios');

// Configuration
const model = "ep-20250731234418-8kgvb"; // Replace with your actual model ID
const ARK_API_KEY = "f384354f-c1c5-4705-a96a-9013ae1dcaa2";
const SERPAPI_API_KEY = "088ca307d157c6e3a613c93763208773428aac757e5f43837155221fbc20e55a";
const ARK_BASE_URL = "https://ark.ap-southeast.bytepluses.com/api/v3";

/**
 * Prompts the user to enter a URL for an image.
 */
function getImageInputFromUser() {
    return new Promise((resolve, reject) => {
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });

        const askForUrl = () => {
            rl.question('Please enter the URL of the image: ', (imageUrl) => {
                const trimmedUrl = imageUrl.trim();
                if (trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://')) {
                    rl.close();
                    resolve(trimmedUrl);
                } else {
                    console.log('Error: Invalid URL. Please enter a valid http or https URL.');
                    process.exit(1);
                }
            });
        };

        askForUrl();
    });
}

/**
 * Performs SerpAPI search with the given query
 */
async function performSerpApiSearch(query) {
    if (!SERPAPI_API_KEY) {
        console.log('Error: SERPAPI_API_KEY environment variable not set.');
        return [];
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
        console.log(`Error performing SerpAPI search: ${error.message}`);
        return [];
    }
}

/**
 * Makes a request to the Ark API
 */
async function makeArkApiRequest(messages) {
    try {
        const response = await axios.post(`${ARK_BASE_URL}/chat/completions`, {
            model: model,
            messages: messages
        }, {
            headers: {
                'Authorization': `Bearer ${ARK_API_KEY}`,
                'Content-Type': 'application/json'
            }
        });

        if (response.data.usage) {
            console.log(`LLM Analysis - Input Tokens: ${response.data.usage.prompt_tokens}, Output Tokens: ${response.data.usage.completion_tokens}`);
        }

        return response.data.choices[0].message.content;
    } catch (error) {
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

/**
 * Main function
 */
async function main() {
    try {
        // Get image input from user
        const imageInput = await getImageInputFromUser();
        console.log(`You selected: ${imageInput}`);

        console.log(`\nAnalyzing image quality and determining resell price range for: ${imageInput}`);

        // Step 1: LLM generates a keyword for SerpAPI search
        console.log('\nLLM generating search keyword...');
        const keywordMessages = [{
            role: "user",
            content: [
                { type: "image_url", image_url: { url: imageInput } },
                { type: "text", text: "Based on this image, identify the main item, its series, and year of production. Only output the item, series, and year, nothing else." }
            ]
        }];

        const itemInfo = await makeArkApiRequest(keywordMessages);
        console.log(`Identified item: ${itemInfo.trim()}`);

        // Step 2: Perform SerpAPI search with the generated keyword
        console.log('\nPerforming SerpAPI search...');
        const searchQuery = `${itemInfo.trim()} ราคา มือสอง`;
        const searchResults = await performSerpApiSearch(searchQuery);
        
        console.log('SerpAPI Search Results:');
        searchResults.forEach(result => {
            console.log(`- ${result.title || 'No title'} - ${result.link || 'No link'}`);
        });

        // Step 3: LLM analyzes search results and image to suggest price range
        console.log('\nLLM analyzing search results and image for price range...');
        console.log(`Item identified: ${itemInfo.trim()}`);
        
        const finalAnalysis = await analyzeImageWithLlm(imageInput, searchResults);
        console.log('\nLLM Analysis and Suggested Resell Price:');
        console.log(finalAnalysis);

    } catch (error) {
        console.error(`Error: ${error.message}`);
        process.exit(1);
    }
}

// Run the main function if this script is executed directly
if (require.main === module) {
    main();
}

module.exports = {
    getImageInputFromUser,
    performSerpApiSearch,
    analyzeImageWithLlm,
    main
};