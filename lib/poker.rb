require 'colorize'
require 'byebug'

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



class Hand
  POKER_HANDS = [
    {
      name: "Royal Flush",
      rank: 1,
      match: Proc.new do |cards|
        royal = cards.all? { |card| card.value > 9 }
        flush(cards) && royal
      end,
      tiebreaker: Proc.new { |v| 0 }
    },

    {
      name: "Straight Flush",
      rank: 2,
      match: Proc.new do |cards|
        flush(cards) && straight(cards)
      end,
      tiebreaker: Proc.new do |cards, other_cards|
        tb_straights(cards, other_cards)
      end
    },

    {
      name: "Four of a Kind",
      rank: 3,
      match: Proc.new do |cards|
        group_of?(4, cards)
      end,
      tiebreaker: Proc.new do |cards, other_cards|
        tb_big_group(cards, other_cards)
      end
      },

    {
      name: "Full House", rank: 4,
      match: Proc.new do |cards|
        group_of?(3, cards) && group_of?(2, cards)
      end,
      tiebreaker: Proc.new do |cards, other_cards|
        tb_big_group(cards, other_cards)
      end
    },

    {
      name: "Flush", rank: 5,
      match: Proc.new do |cards|
        flush(cards)
      end,
      tiebreaker: Proc.new do |cards, other_cards|
        my_cards = cards.sort.reverse
        his_cards = other_cards.sort.reverse
        tb_card_lists(my_cards, his_cards)
      end
    },

    {
      name: "Straight", rank: 6,
      match: Proc.new do |cards|
        no_duplicates = cards.group_by { |card| card.value }.length == 5
        straight(cards) && no_duplicates
      end,
      tiebreaker: Proc.new do |cards, other_cards|
        tb_straights(cards, other_cards)
      end
    },

    {
      name: "Three of a Kind", rank: 7,
      match: Proc.new do |cards|
        group_of?(3, cards)
      end,
      tiebreaker: Proc.new do |cards, other_cards|
        tb_big_group(cards, other_cards)
      end
    },

    {
      name: "Two Pair", rank: 8,
      match: Proc.new do |cards|
        cards.group_by { |card| card.value }.length == 3
      end,
      tiebreaker: Proc.new do |cards, other_cards|
        my_pair_values = pairs(cards)
        his_pair_values = pairs(other_cards)
        my_single_card = (cards.map { |card| card.value } - my_pair_values)
        his_single_card = (other_cards.map { |card| card.value } - his_pair_values)
        tb_card_lists(my_pair_values + my_single_card, his_pair_values + his_single_card)
      end
    },

    {
      name: "One Pair", rank: 9,
      match: Proc.new do |cards|
        cards.group_by { |card| card.value }.length == 4
      end,
      tiebreaker: Proc.new do |cards, other_cards|
        my_pair = pairs(cards)
        his_pair = pairs(other_cards)
        my_remaining_cards = (cards.map { |card| card.value } - my_pair).sort.reverse
        his_remaining_cards = (other_cards.map { |card| card.value } - his_pair).sort.reverse
        tb_card_lists(my_pair + my_remaining_cards, his_pair + his_remaining_cards)
      end
    },

    {
      name: "High Card", rank: 10,
      match: Proc.new { |v| true },
      tiebreaker: Proc.new do |cards, other_cards|
        my_cards = cards.map { |card| card.value }.sort.reverse
        his_cards = other_cards.map { |card| card.value }.sort.reverse
        tb_card_lists(my_cards, his_cards)
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

  def self.pairs(cards)
    by_value = cards.group_by { |card| card.value }
    by_value.reject { |c, card_group| card_group.length == 1}.keys.sort.reverse
  end

  def self.tb_big_group(cards, other_cards)
    my_max = cards.group_by { |card| card.value }.max_by { |c, card_group| card_group.length }[0]
    other_max = other_cards.group_by { |card| card.value }.max_by { |c, card_group| card_group.length }[0]
    my_max <=> other_max
  end

  def self.tb_card_lists(cards, other_cards)
    cards.length.times do |i|
      return 1 if cards[i] > other_cards[i]
      return -1 if cards[i] < other_cards[i]
    end
    0
  end

  def self.tb_straights(cards, other_cards)
    my_high_card = cards.sort[3].value == 5 ? 5 : cards.sort[4].value
    his_high_card = cards.sort[3].value == 5 ? 5 : cards.sort[4].value
    my_high_card <=> his_high_card
  end

  def self.flush(cards)
    cards.group_by { |card| card.suit }.length == 1
  end

  def self.group_of?(num, cards)
    cards.group_by { |card| card.value }.values.any? { |group| group.length == num }
  end

  def self.straight(cards)
    check_cards = cards.map { |card| card.value }.sort
    high_ace_straight = check_cards[4] - check_cards[0] == 4
    low_ace_straight = check_cards[3] == 5 && check_cards[4] = 14
    high_ace_straight || low_ace_straight
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
    rescue RuntimeError => e
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
    return if everyone_folds(get_bets)
    discards
    return if everyone_folds(get_bets)
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

  def everyone_folds(winner)
    if winner
      puts "Everyone folded - #{winner.name} wins!!"
      winner.change_purse (@pot)
      @pot = 0
      return true
    end
    false
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
    current_bet, last_raising = 10, @players[1]
    i = 0
    first_round = true
    loop do
      i += 1
      currently_betting = @players[i % @players.length]
      break if currently_betting == last_raising && !first_round
      first_round = false
      next if currently_betting.folded?
      if @players.count { |player| !player.folded? } == 1
        return currently_betting
      end
      puts "It's #{currently_betting.name}'s turn."
      puts currently_betting.display_hand
      bet = currently_betting.get_action([0, current_bet].max)
      @pot += bet
      last_raising = currently_betting if bet > current_bet
      current_bet = bet if bet != 0
    end
    return nil
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
        next
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



if __FILE__ == $PROGRAM_NAME
  joshua = Player.new("Joshua", 800)
  bob = Player.new("Bob", 500)
  judy = Player.new("Judy", 1000)
  g = Game.new([joshua, bob, judy])
  g.play
end



#############################



class Array
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
end
