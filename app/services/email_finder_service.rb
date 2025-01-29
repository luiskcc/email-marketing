class EmailFinderService
    include HTTParty  # Add this
    base_uri 'https://api.openai.com/v1'  # Add this
    require 'nokogiri'

    USER_AGENTS = [
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/91.0.4472.124',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Firefox/89.0'
    ]

    

    def initialize(prospects)
        @prospects = Array(prospects)
        @total = @prospects.size
        @api_url = "https://api.groq.com/openai/v1"
        @processed = 0
        @headers = {
            "Content-Type" => "application/json",
            "Authorization" => ENV["GROQ_API_KEY"]  # Use ENV variable
        }
    end

    def find_emails
        @prospects.each do |prospect|
            begin
                puts "Processing prospect #{@processed += 1} of #{@total}: #{prospect.business_name}"
                
                content = get_website_content(prospect.website)

                if content.blank?
                    puts "No content found for #{prospect.business_name} and #{prospect.website}"
                    next
                end

                gpt_emails = gpt_email_finder(content)

                if gpt_emails.present?
                    puts "Found emails for #{prospect.business_name} GPT emails: #{gpt_emails.join(', ')}"
                    prospect.update(email: gpt_emails)
                else
                    puts "No emails found for #{prospect.business_name}"
                end

                puts "Total emails found: #{prospect.email.count}"

            rescue => exception
                puts "Error processing prospect #{prospect.business_name}: #{exception.message}"
            end

            
        end
    end

    private

    def get_website_content(website)
        puts "Checking website: #{website}"

        main_page = fetch_page(website)
        return nil unless main_page
        main_content = extract_page_content(main_page)

        secondary_pages = fetch_sub_pages(main_page)
        secondary_content= extract_sub_pages(secondary_pages)
        [main_content, secondary_content].join("\n")
    end


    def fetch_page(url)
        response = self.class.get(
            url,
            headers: {
                "User-Agent" => USER_AGENTS.sample,
                'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9'
            },
            timeout: 10
        )
        
        if response.success?
            Nokogiri::HTML(response.body)
            puts "Fetched page: #{response.body}"
        else
            puts "Failed to fetch page: #{response.code}"
            nil
        end
        
    end
    

    def extract_page_content(page)
        return nil unless page
        
        selectors = [
            # Basic HTML elements
            'body', # Gets all content
            'main', # Main content area
            'article', # Article content
            
            # Text elements
            'p', 'span', 'a', # Basic text and link elements
            'h1, h2, h3, h4, h5, h6', # All heading levels

            #Navigational elements
            'nav',
            'header',
            'footer',
            
            # Common contact-related classes/IDs
            '[class*="contact"]', # Matches any class containing "contact"
            '[class*="email"]', # Matches any class containing "email"
            '[class*="team"]', # Matches any class containing "team"
            '[id*="contact"]',# Matches any ID containing "contact"
            '.contact-info',
            '.team-member',
            'address',
            
            # Specific contact sections
            'address',
            '.contact-info',
            '.contact-details',
            '.contact-information',
            '.team-members',
            '.staff-directory',
            'contact',
            'contact-page',
            '.contact-us',
            
            # Footer (often contains contact info)
            'footer',
            '.footer',
            
            # Common container elements
            'div[class*="contact"]',
            'section[class*="contact"]'
        ]
        
        content = selectors.map do |selector|
            page.css(selector).map(&:text).join(' ')
        end.flatten.join("\n")
        content = content.gsub(/\s+/, ' ')
        content
    end

    def fetch_sub_pages(page)
        links = page.css('a').map { |link| link['href'] }.compact

        contact_links = links.select do |href|
            href.to_s.downcase.match?(/contact|email|team|staff|directory|about|careers|support|help|faq|contact-us/)
        end

        contact_links.map do |href|
            begin
                uri = URI.parse(href)
                if uri.host.nil?
                    base_uri = URI.parse(@current_website)
                    URI.join(base_uri, href).to_s
                else
                    href
                end
            rescue => e
                puts "Error fetching sub-page #{href}: #{e.message}"
                nil
            end
        end.compact.uniq
        absolute_urls.first(3)
    end

    def extract_sub_pages(urls)
    return "" if urls.blank?

    puts "Processing secondary pages..."
    sub_contents = []

    urls.each do |url|
        puts "  Checking: #{url}"
        if page = fetch_page(url)
        if content = extract_page_content(page)
            sub_contents << content
            puts "  ✓ Content extracted"
        end
        end
        sleep(1) # Rate limiting
    end

    sub_contents.join("\n")
    end


    def gpt_email_finder(content)
        body = {
            "model": "deepseek-r1-distill-llama-70b",
            "messages": [
            {
                "role": "system",
                "content": "Extract email addresses and related information from website content. Return valid JSON only."
            },
            {
                "role": "user",
                "content": "Based on this website content: #{content}

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
            }
            ],
            "temperature": 0.2
        }

    response = HTTParty.post(@api_url, headers: @headers, body: body.to_json)
    
    if response.success?
            parsed_response = JSON.parse(response.body)
            result = JSON.parse(parsed_response['choices'][0]['message']['content'])
            
            if result['email'] && result['email'] != 'none'
            puts "✓ Found: #{result['name']} (#{result['role']}) - #{result['email']}"
            # Return as array
            result['email'].to_s
            else
                nil
            end
        else
            puts "✗ API Error: #{response.code}"
            nil
        end
        rescue => e
        puts "✗ GPT Error: #{e.message.split("\n").first}"
        nil
    end 
end


