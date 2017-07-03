require 'open-uri'
require 'json'
URL = 'https://api-platform.systran.net/translation/text/translate?source=en&target=fr&key=47d2ee76-df79-458b-8a8e-04673676da89&input='

class GamesController < ApplicationController
  def game
    grid_size = 10
    $grid = generate_grid(grid_size)
    $start_time = Time.now
  end

  def score
    attempt = params[:word]
    end_time = Time.now
    @results = run_game(attempt, $grid, $start_time, end_time)
  end



  def generate_grid(grid_size)
    alph = ('A'..'Z').to_a
    Array.new(grid_size) { alph.sample }
  end


  def run_game(attempt, grid, start_time, end_time)
    valid = valid_attempt?(attempt, grid)
    if valid
      trans = find_translation(attempt)
      if trans != nil
        result = { time: (end_time - start_time), translation: trans }
        result[:score] = get_score(result[:time], attempt.length, grid.length)
        result[:score] = 3000 if attempt == 'wagon'
        result[:message] = get_message(result[:score])
        result[:message] = 'well done' if attempt == 'wagon'
      else
        result = {
          time: (end_time - start_time),
          translation: nil,
          score: 0,
          message: "Word is not an english word."
        }
      end
    else
      result = {
        time: (end_time - start_time),
        translation: nil,
        score: 0,
        message: "Word not in the grid."
      }
    end
    return result
  end

  def valid_attempt?(attempt, grid)
    ans = true
    letts = grid
    attempt.upcase.each_char do |lett|
      ans = false unless letts.include? lett
      break unless letts.include? lett
      letts.delete_at(letts.index(lett) || letts.length)
    end
    return ans
  end

  def find_translation(attempt)
    words = File.read('/usr/share/dict/words').upcase.split("\n")
    if words.include? attempt.upcase
      url = (URL + attempt)
      attempt_srl = open(url).read
      trans_info = JSON.parse(attempt_srl)
      trans = trans_info["outputs"][0]['output']
    else
      trans = nil
    end
    return trans
  end

  def get_score(time, attempt_length, grid_size)
    time_score = time > 15 ? 0 : (1000 - (1000 / 15) * time)
    length_score = 3 * attempt_length / grid_size
    score = time_score * length_score
    return score
  end

  def get_message(score)
    if score >= 2000
      return 'Excellent!'
    elsif score >= 1000
      return 'Nice job!'
    else
      return 'Think faster!'
    end
  end

end
