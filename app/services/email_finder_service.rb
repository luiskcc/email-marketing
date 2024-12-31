class EmailFinderService
    include HTTParty  # Add this
    base_uri 'https://api.openai.com/v1'  # Add this

    def initialize(prospects)
        @prospects = prospects
        @api_url = "https://api.openai.com/v1/chat/completions"
        @headers = {
            "Content-Type" => "application/json",
            "Authorization" => "Bearer #{ENV['OPENAI_API_KEY']}"  # Use ENV variable
        }
    end

    def find_emails
        @prospects.each do |prospect|
            puts "Processing prospect: #{prospect.business_name}"
            
            next if prospect.website.blank?
            
            # First, get website content using Perplexity
            website_content = perplexity_call(prospect.website)
            next if website_content.blank?

            query = "Based on this website content: #{website_content}

                Find the CEO/Founder Email:
                - Search for the email address of the company's CEO or founder
                - Include their name if found

                Fallback Options:
                1. C-level executive or department head email
                2. General contact email (only if no personal emails found)

                Guidelines:
                - Exclude generic helpdesk emails unless no alternatives
                - No social media links
                - Must be an email address

                Output Format:
                {
                    \"name\": \"[Person's name]\",
                    \"email\": \"[email address]\",
                    \"role\": \"[CEO/Founder/etc]\"
                }
                
                If no email found, output: {\"email\": \"none\"}"

            begin
                body = {
                    "model": "gpt-4",
                    "messages": [
                        {
                            "role": "user",
                            "content": query
                        }
                    ],
                    "temperature": 0.0
                }

                puts "Making API call for #{prospect.business_name}..."
                response = HTTParty.post(@api_url, body: body.to_json, headers: @headers, timeout: 500)
                
                if response.code == 200
                    puts "Received response: #{response['choices'][0]['message']['content']}"
                    result = JSON.parse(response['choices'][0]['message']['content'])
                    
                    if result['email'] != 'none'
                        prospect.update(
                            email: result['email'],
                            name: result['name']
                        )
                        puts "Updated prospect #{prospect.business_name} with email: #{result['email']}"
                    else
                        puts "No email found for #{prospect.business_name}"
                    end
                else
                    puts "Error for prospect #{prospect.business_name}: #{response['error']['message']}"
                end
            rescue JSON::ParserError => e
                puts "Invalid JSON response for #{prospect.business_name}: #{response['choices'][0]['message']['content']}"
            rescue => e
                puts "Exception for prospect #{prospect.business_name}: #{e.message}"
            end
            
            sleep(2)  # Rate limiting
        end
    end

    private

    def perplexity_call(website)
        perplexity_url = "https://api.perplexity.ai/chat/completions"
        headers = {
            "Content-Type" => "application/json",
            "Authorization" => "Bearer #{ENV['PERPLEXITY_API_KEY']}"
        }

        body = {
            model: "sonar-small-online",
            messages: [
                {
                    role: 'system',
                    content: "Extract content from the website and its subpages #{website} and return the content in text format."
                }
            ]
        }

        begin
            response = HTTParty.post(perplexity_url, headers: headers, body: body.to_json)
            if response.code == 200
                response['choices'][0]['message']['content']
            else
                puts "Perplexity API error: #{response['error']['message']}"
                nil
            end
        rescue => e
            puts "Perplexity API exception: #{e.message}"
            nil
        end
    end
end