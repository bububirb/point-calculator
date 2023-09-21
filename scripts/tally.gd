extends Node

var tally_options = [simple_sum, simple_clamp, two_phase_clamp, league_of_trouble]
var tally_display_names = ["Simple Sum", "Simple Clamp", "Two Phase Clamp", "LoT"]
var tally_function = simple_sum

var clamped_tally_min_score = 100 # Todo: Expose to GUI

func tally_session(session_name):
	var match_data : MatchData
	var target_match_data_path = Globals.SESSION_DATA_PATH + session_name + "/match_data/"
	var tally_scores = {}
	for file in Globals.list_match_data(session_name):
		match_data = ResourceLoader.load(target_match_data_path + file)

		for i in match_data.winning_scores.size():
			var id = match_data.winning_player_ids[i]
			if not tally_scores.has(id):
				tally_scores[id] = 0
			tally_scores[id] += match_data.winning_scores[i]

			id = match_data.losing_player_ids[i]
			if not tally_scores.has(id):
				tally_scores[id] = 0
			tally_scores[id] += match_data.losing_scores[i]
		for override in match_data.overrides:
			var id = override.player_id
			if not tally_scores.has(id):
				tally_scores[id] = 0
			if override.relative:
				tally_scores[id] += override.score
			else:
				tally_scores[id] = override.score
	return tally_scores

func tally_all_sessions(tally_scores : Dictionary):
	for key in tally_scores.keys():
		tally_scores[key] = 0
	for session in Globals.list_ordered_session_folders():
		var match_data : MatchData
		var target_match_data_path = Globals.SESSION_DATA_PATH + session + "/match_data/"
		for file in Globals.list_match_data(session):
			match_data = ResourceLoader.load(target_match_data_path + file)
			for i in match_data.winning_scores.size():
				var id = match_data.winning_player_ids[i]
				if id != "":
					if tally_scores.has(id):
						tally_scores[id] = tally_function.call(tally_scores[id], match_data.winning_scores[i])
				id = match_data.losing_player_ids[i]
				if id != "":
					if tally_scores.has(id):
						tally_scores[id] = tally_function.call(tally_scores[id], match_data.losing_scores[i])
			for override in match_data.overrides:
				var id = override.player_id
				if tally_scores.has(id):
					if override.relative:
						tally_scores[id] += override.score
					else:
						tally_scores[id] = override.score
	# Round tally results
	for key in tally_scores.keys():
		tally_scores[key] = round(tally_scores[key])
	tally_scores = sort_dict(tally_scores)
	return tally_scores

func tally_matches_per_player(players : Dictionary):
	for key in players.keys():
		players[key] = 0
	for session in Globals.list_ordered_session_folders():
		var match_data : MatchData
		var target_match_data_path = Globals.SESSION_DATA_PATH + session + "/match_data/"
		for file in Globals.list_match_data(session):
			# Todo: Sort by naturalnocasecmp
			match_data = ResourceLoader.load(target_match_data_path + file)
			
			for i in match_data.winning_scores.size():
				var id = match_data.winning_player_ids[i]
				if id != "":
					if players.has(id):
						players[id] += 1
				
				id = match_data.losing_player_ids[i]
				if id != "":
					if players.has(id):
						players[id] += 1
	players = sort_dict(players)
	return players

func select_tally_option(index):
	tally_function = tally_options[index]
	return tally_function

# Tally functions. Takes two arguments, total and score.
# total is the player's current total and score is the score to be added.

func simple_sum(total, score):
	# Sums up all scores, can result in negatives
	return total + score

func simple_clamp(total, score):
	# Negates losses below minimum score
	if total <= clamped_tally_min_score and score < 0:
		score = 0
	return total + score

func two_phase_clamp(total, score):
	# Same as Simple Clamp, but applies 50% of losses below minimum score * 2.5
	if score < 0:
		if total <= clamped_tally_min_score:
			score = 0 # Negate losses
		elif total <= clamped_tally_min_score * 2.5:
			score *= 0.5 # 50% loss reduction
	return total + score

func league_of_trouble(total, score):
	# Special tally method used in LFT's ranked system
	if score < 0:
		if total <= 100: # Score is below or equals 100
			score = 0 # Negate losses
		elif total <= 250: # 101 - 250
			score *= 0.5 # 50% loss applied
		elif total <= 500: # 251 - 500
			score *= 0.5 # Full loss applied
		else: # 501+
			score *= 1.25 # 125% loss applied
	return total + score

func sort_dict(dict):
	var sorted_dict = {}
	var sorted_keys = dict.keys()
	sorted_keys.sort()
	for key in sorted_keys:
		sorted_dict[key] = dict[key]
	return sorted_dict
