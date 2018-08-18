class GooglePlaySubscription < ApplicationRecord

	def self.get_access_and_refresh_tokens(code)
		params2 = {grant_type: "authorization_code", code: code, client_id: ENV["GOOGLE_PLAY_CLIENT_ID"], client_secret: ENV["GOOGLE_PLAY_CLIENT_SECRET"], redirect_uri: "http://arsr-app1.herokuapp.com/googleplaysubscriptions/getAccessAndRefreshTokens"}
		x = Net::HTTP.post_form(URI.parse("https://accounts.google.com/o/oauth2/token"),params2)
		JSON.parse(x.body)
	end

	def self.get_access_token_from_refresh_token
		params2 = {grant_type: "refresh_token", client_id: ENV["GOOGLE_PLAY_CLIENT_ID"], client_secret: ENV["GOOGLE_PLAY_CLIENT_SECRET"], refresh_token: ENV["GOOGLE_PLAY_REFRESH_TOKEN"]}
		x = Net::HTTP.post_form(URI.parse("https://accounts.google.com/o/oauth2/token"),params2)
		res = JSON.parse(x.body)
		res["access_token"]
	end

	def self.subscribe_with_google_play(token, receipt, email)
		at = get_access_token_from_refresh_token
		url = "https://www.googleapis.com/androidpublisher/v3/applications/com.kojigame.koji/purchases/subscriptions/sub1/tokens/" + token + "?access_token=" + at
		res = Net::HTTP.get(URI.parse(url))
		subscription_response = JSON.parse(res)
		receipt_response = JSON.parse(receipt)
		if ( (subscription_response["paymentState"] == 1) && (receipt_response["purchaseState"] == 0) )
			subs = GooglePlaySubscription.new(email: email, package_name: receipt_response["packageName"], order_id: receipt_response["orderId"], purchase_token: receipt_response["purchaseToken"], product_id: receipt_response["productId"], kind: subscription_response["kind"], start_time_millis: subscription_response["startTimeMillis"], expiry_time_millis: subscription_response["expiryTimeMillis"], price_amount_micros: subscription_response["price_amount_micros"], payment_state: subscription_response["paymentState"])
			if (subs.save)
				res = subs.id
			else
				res = -1
			end
		else
			res = -1
		end
		puts " "
		puts " this was a test of new setup"
		puts " "
		puts subscription_response["kind"]
		puts " "
		puts receipt_response
		puts " "
		puts receipt_response["packageName"]
		puts " "
		puts res
		return res
	end

end