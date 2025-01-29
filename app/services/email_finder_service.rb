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
                if content.present?
                    email = fetch_email_from_main_page(content)
                    if email.present?
                        Rails.logger.info("Email found for prospect #{prospect.business_name}: #{email.join(', ')}")
                        prospect.update(email: email.first)
                        Rails.logger.info("Email updated for prospect #{prospect.business_name}")
                    else
                        Rails.logger.info("No email found for prospect #{prospect.business_name}")
                    end
                end
            rescue => exception
                puts "Error processing prospect #{prospect.business_name}: #{exception.message}"
            end
        end
        Rails.logger.info("Email finder serice completed")
    end


    def get_website_content(url)
        Rails.logger.info("Fetching content from #{url}")
        begin
            html = URI.open(url, 'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36').read
            document = Nokogiri::HTML(html)
            content = document.text
        rescue => exception
            Rails.logger.error("Error processing prospect #{prospect.business_name}: #{exception.message}")
        end
        content
    end

    def fetch_email_from_main_page(content)
        email_pattern = /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z]{2,}\b/i
        email = content.scan(email_pattern)
        if email.any?
            Rails.logger.info("Email found in main page #{email.join(', ')}")
            if prospect.update(email: email.first)
                Rails.logger.info("Email updated for prospect #{prospect.business_name}")
            else
                Rails.logger.error("Failed to update email for prospect #{prospect.business_name}")
            end
        end
        email
    end
end


