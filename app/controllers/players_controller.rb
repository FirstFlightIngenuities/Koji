class PlayersController < ApplicationController

	def create
		if (params["email"].blank?)
			@email = nil 
			emailValid = false
		else
			@email = params["email"].to_s.downcase
			emailValid = Player.validate_email(params["email"])
		end
		if (params["cellphone"].blank?) 
			@cell = nil
			cellValid = true
		else
			@cell = params["cellphone"].to_s
			cellValid = Player.validate_cellphone(params["cellphone"])
		end
		output = "BAD"
		if (cellValid && emailValid && (params["password1"].to_s == params["password2"].to_s) && (!params["email"].blank? || !params["cellphone"].blank?))
			player = Player.new(email: @email, cellphone: @cell, display_name: params["display_name"], password: params["password1"], phone_country: "USA", game_version: params["game_version"], subscribed: 0, email_verified: 0, cellphone_verified: 0)
			if (player.save! && !player.id.blank?)
				subscription_result = Subscription.subscription_enroll(params[:stripeToken], params[:stripeEmail])
				if (subscription_result[0] == 1)
					player.create_player_gaming_history(current_total: 0, current_high_score: 0, history: "")
					player.subscribed = 1
					player.date_first_subscribed = DateTime.now
					player.create_subscription(date_first_subscribed: DateTime.now, pp_subscription_id: subscription_result[1], status: 1, status_description: "active", date_last_charged: DateTime.now, payment_provider_id: 1)
					player.create_pp_customer_info(payment_provider_id: 1, pp_customer_id: subscription_result[2])
					player.save
					output = "OK"
				else
					player.destroy
				end
			end
		end
		ActiveRecord::Base.connection.close
		render plain: output
	end

	def update
		player = Player.find(session["player_id"])
		destroyed = 0
		if (params["code"].to_i == 1)
			player.password = params["password"]
		elsif (params["code"].to_i == 2)
			if (!params["email"].blank? && !Player.find_by(email: params[:email]))
				player.email = params["email"].to_s.downcase
			end
			if (!params["cellphone"].blank? && !Player.find_by(cellphone: params[:cellphone]))
				player.cellphone = params["cellphone"]
			end
		elsif ((params["code"].to_i == 3) && (params["cancel"].to_s.downcase == "cancel"))
			result = Player.cancel_membership(session["player_id"])
			if (result == 1)
				player.destroy
				destroyed = 1
			end
			session[:player_id] = nil
		elsif (params["code"].to_i == 4)
			session[:player_id] = nil
		end 
		output = "BAD"
		if ((destroyed == 1) || player.save!)
			output = "OK"			
		end
		render plain: output
	end

	def login
		@player = nil
		output = "BAD"
		if (!params["email"].blank?)
			@player = Player.find_by(email: params["email"].to_s.downcase)
		elsif (!params["cellphone"].blank?)
			@player = Player.find_by(cellphone: params["cellphone"].to_s)
		end

		if(!@player.blank? && (params[:reset].to_s == "0"))
			if (params[:password] == @player.password)
				session["player_id"] = @player.id
				output = "OK"
			end
		elsif (params[:reset].to_s == "0")
			Player.send_password_reset_confirmation_code(@player.id, params["cellphone"], params["email"])
			output = "RESET SENT"
		end
		render plain: output
	end

	def show
		player = Player.find(session["player_id"])
		history = PlayerGamingHistory.find_by(player_id: session["player_id"]).history
		response = {}
		response["email"] = player.email
		response["cellphone"] = player.cellphone
		if (!history.blank?)
			response["history"] = JSON.parse(history)
		else
			response["history"] = ""
		end
		res = JSON.generate(response)
		output = "OK_?*#{res}"
		render plain: output
	end

	def check_email
		player = Player.find_by(email: params["data"].to_s.downcase)
		output = "DUPLICATE"
		if (!player) 
			output = "OK"
		end
		render plain: output
	end

	def check_cellphone
		player = Player.find_by(cellphone: params["data"].to_s)
		output = "DUPLICATE"
		if (!player) 
			output = "OK" 
		end
		render plain: output
	end

	def check_displayname
		player = Player.find_by(display_name: params["data"])
		output = "DUPLICATE"
		if (!player) 
			output = "OK"
		end
		render plain: output
	end

	def startup_message
		render plain: "1"
	end

  def player_params
    params.require(:player).permit(:email, :cellphone, :displayname)
  end

end
