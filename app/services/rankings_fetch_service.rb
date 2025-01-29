class RankingsFetchService
    def initialize(user)
        @user = user
        @location = "@51.8944857,-0.8919045,13.45z"
        @q = "Hotels"
    end

    def fetch_rankings
        prospect_params = {
            api_key: ENV['SERPAPI_API_KEY'],
            engine: 'google_maps',
            type: 'search',
            google_domain: 'google.com',
            q: @q,
            ll: @location,
            hl: 'en',
        }

        begin
            puts "Making API call..."
            prospect_search = GoogleSearch.new(prospect_params)
            response = prospect_search.get_hash
            
            puts "Response received: #{response.present? ? 'Yes' : 'No'}"
            return if response.nil?
            
            prospect_hash = response.deep_symbolize_keys
            puts "Number of results found: #{prospect_hash[:local_results]&.length || 0}"
            
            return if prospect_hash[:local_results].nil?

            # Find the #1 ranked business
            top_business = prospect_hash[:local_results].find { |r| r[:position] == 1 }
            puts "Top business found: #{top_business&.dig(:title)}"

        

            prospect_hash[:local_results].each do |result|
                if result[:website].present?
                    begin
                        prospect = Prospect.create!(
                            industry: result[:type],
                            website: result[:website],
                            business_name: result[:title],
                            rating: result[:rating],
                            reviews_number: result[:reviews_number],
                            phone_number: result[:phone_number],
                            address: result[:address],
                            location: result[:location],
                            search_term: @q,
                            ranking: result[:position],
                            top_competitor: result[:position] == 1 ? nil : top_business&.dig(:title)
                        )
                        puts "Created prospect: #{prospect.business_name} (Rank: #{prospect.ranking})"
                    rescue => e
                        puts "Error creating prospect: #{e.message}"
                    end
                end
            end
        rescue => exception
            puts "Error: #{exception.message}"
        end
    end
end