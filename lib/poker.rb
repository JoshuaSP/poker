require 'colorize'

Card = Struct.new(:value, :suit) do

  SUIT_STRINGS = {
    :clubs    => "♣",
    :diamonds => "♦",
    :hearts   => "♥",
    :spades   => "♠"
  }

  SUIT_COLORS = {
    :clubs    => :black,
    :diamonds => :red,
    :hearts   => :red,
    :spades   => :black
  }

  FACE_CARDS = {
    11  =>  "J",
    12  =>  "Q",
    13  =>  "K",
    14  =>  "A"
  }

  def to_s
    type = (value < 11 ? value.to_s : FACE_CARDS[value])
    (type + SUIT_STRINGS[suit]).colorize(color: SUIT_COLORS[suit], background: :white)
  end

  def <=> (other)
    case
    when self.value < other.value
      return -1
    when self.value == other.value
      return 0
    when self.value > other.value
      return 1
    end
  end
end

class Deck
  SUITS = [:clubs, :diamonds, :hearts, :spades]

  attr_accessor :cards

  def initialize
    @cards = []
    SUITS.each do |suit|
      (2..14).each do |value|
        @cards << Card.new(value, suit)
      end
    end
    @cards.shuffle!
  end

  def deal(n)
    cards.pop(n)
  end
end

##  TO DO:  FIX ALL THE RETURNS IN TIEBREAKERS


class Hand
  POKER_HANDS = [
    {
      name: "Royal Flush",
      rank: 1,
      match: Proc.new do |cards|
        cards.group_by { |card| card.suit }.length == 1 && cards.all? { |card| card.value > 9 }
      end,
      tiebreaker: Proc.new { |cards, other_cards| :tie }
    },

    {
      name: "Straight Flush", rank: 2,
      match: Proc.new do |cards|
        cards.group_by { |card| card.suit }.length == 1 && cards.sort[4].value - cards.sort[0].value == 4
      end,
      tiebreaker: Proc.new do |cards, other_cards|
        cards.sort[4] <=> other_cards.sort[4]
      end
    },

    {
      name: "Four of a Kind", rank: 3,
      match: Proc.new do |cards|
        cards.group_by { |card| card.value }.values.any? { |group| group.length == 4 }
      end,
      tiebreaker: Proc.new do |cards, other_cards|
        my_max = cards.group_by { |card| card.value }.max_by { |card_value, card_group| card_group.length }[0]
        other_max = other_cards.group_by { |card| card.value }.max_by { |card_value, card_group| card_group.length }[0]
        my_max <=> other_max
      end
      },

    {
      name: "Full House", rank: 4,
      match: Proc.new do |cards|
        grouped_cards = cards.group_by { |card| card.value }.values
        grouped_cards.any? { |group| group.length == 3 } && grouped_cards.any? { |group| group.length == 2 }
      end,
      tiebreaker: Proc.new do |cards, other_cards|
        my_max = cards.group_by { |card| card.value }.max_by { |card_value, card_group| card_group.length }[0]
        other_max = other_cards.group_by { |card| card.value }.max_by { |card_value, card_group| card_group.length }[0]
        my_max <=> other_max
      end
    },

    {
      name: "Flush", rank: 5,
      match: Proc.new do |cards|
        grouped_cards = cards.group_by { |card| card.suit }.length == 1
      end,
      tiebreaker: Proc.new do |cards, other_cards|
        my_cards = cards.sort.reverse
        his_cards = other_cards.sort.reverse

        cards.length.times do |i|
          return 1 if my_cards[i] > his_cards[i]
          return -1 if my_cards[i] < his_cards[i]
        end
        0
      end
    },

    {
      name: "Straight", rank: 6,
      match: Proc.new do |cards|
        cards.sort[4].value - cards.sort[0].value == 4 && cards.group_by { |card| card.value }.length == 5
      end,
      tiebreaker: Proc.new do |cards, other_cards|
        cards.sort[0] <=> other_cards.sort[0]
      end
    },

    {
      name: "Three of a Kind", rank: 7,
      match: Proc.new do |cards|
        cards.group_by { |card| card.value }.values.any? { |group| group.length == 3 }
      end,
      tiebreaker: Proc.new do |cards, other_cards|
        my_max = cards.group_by { |card| card.value }.max_by { |card_value, card_group| card_group.length }[0]
        other_max = other_cards.group_by { |card| card.value }.max_by { |card_value, card_group| card_group.length }[0]
        my_max <=> other_max
      end
    },

    {
      name: "Two Pair", rank: 8,
      match: Proc.new do |cards|
        cards.group_by { |card| card.value }.length == 3
      end,
      tiebreaker: Proc.new do |cards, other_cards|
        my_pair_values = cards.group_by { |card| card.value }.reject { |card_value, card_group| card_group.length == 1}.keys.sort.reverse
        his_pair_values = other_cards.group_by { |card| card.value }.reject { |card_value, card_group| card_group.length == 1}.keys.sort.reverse
        my_pair_values.each_index do |i|
          return -1 if my_pair_values[i] < his_pair_values[i]
          return 1 if  my_pair_values[i] > his_pair_values[i]
        end
        (cards.map { |card| card.value } - my_pair_values)[0] <=> (other_cards.map { |card| card.value } - his_pair_values)[0]
      end
    },

    {
      name: "One Pair", rank: 9,
      match: Proc.new do |cards|
        cards.group_by { |card| card.value }.length == 4
      end,
      tiebreaker: Proc.new do |cards, other_cards|
        my_pair = cards.group_by { |card| card.value }.reject { |card_value, card_group| card_group.length == 1}.keys[0]
        his_pair = other_cards.group_by { |card| card.value }.reject { |card_value, card_group| card_group.length == 1}.keys[0]
        return 1 if my_pair > his_pair
        return -1 if his_pair > my_pair
        my_remaining_cards = (cards.map { |card| card.value } - [my_pair]).sort.reverse
        his_remaining_cards = (other_cards.map { |card| card.value } - [his_pair]).sort.reverse
        my_remaining_cards.each_index do |i|
          return -1 if my_remaining_cards[i] < his_remaining_cards[i]
          return 1 if my_remaining_cards[i] > his_remaining_cards[i]
        end
        0
      end
    }
  ]

  attr_accessor :cards

  def initialize
    @cards = []
  end

  def tie_break(other_hand)
    tie = poker_hand[:tiebreaker].call(cards, other_hand.cards)
  end

  def hand_name
    poker_hand[:name]
  end

  def rank
    poker_hand[:rank]
  end

  def poker_hand
    @my_hand ||= find_my_hand
  end

  def find_my_hand
    POKER_HANDS.each do |p_hand|
      return p_hand if p_hand[:match].call(cards)
    end
  end

  def add_cards(new_cards)
    @cards += new_cards
  end

  def discard(discards)
    discards.sort.reverse.each do |discard|
      raise "bad index you idiot" unless cards.delete_at(discard)
    end
  end

  def display
    display_hand = ''
    cards.each do |card|
      display_hand += card.to_s + ' '
    end
    display_hand.strip
  end
end



class Player
  attr_accessor :hand, :folded, :purse
  attr_reader :name

  def initialize(name, purse)
    @name = name
    @purse = purse
  end

  def folded?
    folded
  end

  def display_hand
    hand.display
  end

  def new_hand(cards)
    @hand = Hand.new
    @hand.add_cards(cards)
  end

  def take_cards(cards)
    @hand.add_cards(cards)
  end

  def change_purse(change)
    @purse += change
  end

  def get_discards(max)
    begin
      puts "which cards do you want to discard?"
      input = gets.chomp.gsub(',',' ').split(' ').map { |index| Integer(index) - 1 }
      raise "Discard only three cards" if input.length > 3
      hand.discard(input)
    rescue => e
      puts e.message
      retry
    end
    input.length
  end

  def get_action(current_bet)
    begin
      puts "Current bet is #{current_bet}. You have #{self.purse} money."
      puts "Raise, check, or fold? (r,c,f)"
      input = gets.chomp.downcase
      case input
      when 'r'
        puts "How much?"
        amount = Integer(gets.chomp)
        raise "you don't have enough money" if amount + current_bet > purse
        change_purse(- amount - current_bet)
        amount + current_bet
      when 'c'
        raise "you don't have enough money" if current_bet > purse
        change_purse(- current_bet)
        current_bet
      when 'f'
        @folded = true
        0
      else
        raise "unrecognized input"
      end
    rescue => e
      puts e.message
      retry
    end
  end

  def tie_break(other_player)
    hand.tie_break(other_player.hand)
  end
end

class Game
  attr_accessor :players, :pot, :deck

  def initialize(players)
    @players = players
    @pot = 0
  end

  def play_round
    start_round
    deal_hands
    get_bets
    discards
    get_bets
    winners = determine_winner
    print_winners(winners)
    settle_pot(winners)
  end

  def settle_pot(winners)
    winners.each do |winner|
      winner.change_purse(pot / winners.length)
    end
    pot = 0
  end

  def play
    loop do
      play_round
      puts "Another round?"
      break if gets.chomp.downcase == 'n'
    end
  end

  def start_round
    @deck = Deck.new
    @players.each { |player| player.folded = false }
    @players.unshift(@players.pop)
  end

  def deal_hands
    @players.each do |player|
      player.new_hand(deck.deal(5))
    end
    puts "Five card draw! Dealing your hand."
  end

  def get_bets
    current_bet, last_raising = -1, 0
    i = 0
    loop do
      i += 1
      currently_betting = @players[i % @players.length]
      next if currently_betting.folded?
      break if currently_betting == last_raising
      puts "It's #{currently_betting.name}'s turn."
      puts currently_betting.display_hand
      bet = currently_betting.get_action([0, current_bet].max)
      @pot += bet
      last_raising = currently_betting if bet > current_bet
      current_bet = bet if bet != 0
    end
  end

  def discards
    @players.reject { |player| player.folded? }.each do |player|
      puts "#{player.name}'s turn to discard."
      puts player.display_hand
      player.take_cards(deck.deal(player.get_discards(3)))
    end
  end

  def print_winners(winners)
    winning_hand = winners[0].hand.hand_name
    if winners.length == 1
      puts "#{winners[0].name} is the winner with a #{winning_hand}!!"
    else
      print "#{winners.map { |winner| winner.name }.to_sentence} are winners with "
      print winning_hand + (winning_hand.last == 'h' ? 'es' : 's') + "!!"
    end
  end

  def break_ties(tied)
    winners = [tied.pop]
    until tied.empty?
      compare = tied.pop
      case winners[0].tie_break(compare)
      when 1
      when 0
        winners << compare
      when -1
        winners = [compare]
      end
    end
    winners
  end

  def determine_winner
    active_players = @players.reject { |player| player.folded? }
    rank_groups = active_players.group_by { |player| player.hand.rank }
    tied_for_first = rank_groups[rank_groups.keys.sort[0]]
    break_ties(tied_for_first)
  end
end





#############################




def to_sentence
  case length
    when 0
      ""
    when 1
      self[0].to_s
    when 2
      "#{self[0]} and #{self[1]}"
    else
      "#{self[0...-1].join(',')} and #{self[-1]}"
  end
end
