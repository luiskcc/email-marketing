class EmailFinderService
    include HTTParty  # Add this
    base_uri 'https://api.openai.com/v1'  # Add this


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
                email = get_website_email(prospect.website)
                if email.present?
                    Rails.logger.info("Email found for prospect #{prospect.business_name}: #{email}")
                    prospect.update(email: email)
                    Rails.logger.info("Email updated for prospect #{prospect.business_name}")
                else
                    Rails.logger.info("No email found for prospect #{prospect.business_name}")
                end
            rescue => exception
                Rails.logger.error("Error processing prospect #{prospect.business_name}: #{exception.message}")
            end
        end
        Rails.logger.info("Email finder serice completed")
    end


    def get_website_email(url)
        Rails.logger.info("Fetching content from #{url}")
        begin
            body = {
                'domain' => url,
                'decision_maker_category' => 'ceo'
            }
            if prospect.business_name.present?
                body['company_name'] = prospect.business_name
            end

            response = HTTParty.post(
                'https://api.anymailfinder.com/v5.0/search/decision-maker.json',
                headers: {
                    'Authorization' => ENV["ANYMAIOL_FINDER_API_KEY"],
                    'Content-Type' => 'application/json',
                },
                body: body.to_json
            )
            if response.success?
                Rails.logger.info("Response from AnyMailFinder: #{response.body}")
                email = response.body['email']
                if email.present?
                    Rails.logger.info("Email found for prospect #{prospect.business_name}: #{email}")
                else
                    Rails.logger.info("No email found for prospect #{prospect.business_name}")
                end
            end
        rescue => exception
            Rails.logger.error("Error processing prospect #{prospect.business_name}: #{exception.message}")
        end
        email
    end
end


