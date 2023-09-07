extends Node

var tally_options = [simple_sum, simple_clamp, two_phase_clamp]
var tally_function = simple_sum

var clamped_tally_min_score = 100 # Todo: Expose to GUI

func tally_session(session_name):
	var match_data : MatchData
	var target_match_data_path = Globals.SESSION_DATA_PATH + session_name + "/match_data/"
	var tally_scores = {}
	for file in Globals.list_match_data(session_name):
		# Todo: Sort by naturalnocasecmp
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
	return tally_scores

func tally_all_sessions():
	var tally_scores = {}
	for session in Globals.list_ordered_session_folders():
		var match_data : MatchData
		var target_match_data_path = Globals.SESSION_DATA_PATH + session + "/match_data/"
		for file in Globals.list_match_data(session):
			# Todo: Sort by naturalnocasecmp
			match_data = ResourceLoader.load(target_match_data_path + file)
			
			for i in match_data.winning_scores.size():
				var id = match_data.winning_player_ids[i]
				if not tally_scores.has(id):
					tally_scores[id] = 0
				tally_scores[id] = tally_function.call(tally_scores[id], match_data.winning_scores[i])
				
				id = match_data.losing_player_ids[i]
				if not tally_scores.has(id):
					tally_scores[id] = 0
				tally_scores[id] = tally_function.call(tally_scores[id], match_data.losing_scores[i])
	# Round tally results
	for key in tally_scores.keys():
		tally_scores[key] = round(tally_scores[key])
	tally_scores = sort_dict(tally_scores)
	return tally_scores

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

func sort_dict(dict):
	var sorted_dict = {}
	var sorted_keys = dict.keys()
	sorted_keys.sort()
	for key in sorted_keys:
		sorted_dict[key] = dict[key]
	return sorted_dict
