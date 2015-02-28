require 'rspec'
require 'rspec/collection_matchers'
require 'poker'

RSpec.describe Card do

    describe "#to_s" do
      context "when card is a number" do
        it "prints properly" do
          card1 = Card.new(5, :hearts)
          card2 = Card.new(7, :clubs)
          expect(card1.to_s).to eq("5♥".colorize(color: :red, background: :white))
          expect(card2.to_s).to eq("7♣".colorize(color: :black, background: :white))
        end
      end

      context "when card is a face card" do
        it "prints properly" do
          card1 = Card.new(11, :hearts)
          expect(card1.to_s).to eq("J♥".colorize(color: :red, background: :white))
        end
      end

      context "when cards are sorted" do
        it "sorts by value" do
          card1 = Card.new(5, :hearts)
          card2 = Card.new(7, :clubs)
          expect([card2,card1].sort).to eq([card1,card2])
        end
      end
    end

end

RSpec.describe Deck do
  subject(:deck) { Deck.new }

  describe 'Deck' do
    context "when initialized" do
      it "has 52 cards" do
        expect(deck.cards).to have(52).cards
        expect(deck.cards[0]).to be_a(Card)
      end
    end
  end

  describe '#deal' do
    context "when called" do
      it "returns an array containg n card objects when passed n" do
        expect(deck.deal(1)).to have(1).card
        expect(deck.deal(1)[0]).to be_a(Card)
        expect(deck.deal(2)).to have(2).cards

      end

      it "does not repeat-deal cards" do
        card1 = deck.deal(1)[0]
        expect(deck.deal(51)).to_not include(card1)
      end
    end
  end
end


RSpec.describe Hand do
  let (:deck) { Deck.new }
  let (:card1) { Card.new(5, :hearts) }
  let (:card2) { Card.new(7, :clubs) }
  subject (:hand) do
    h = Hand.new
    h.cards = [card1, card2]
    h
  end


  describe '#add_cards' do
    context 'when passed an array of cards' do
      it 'adds cards to an empty hand' do
        hand.cards = []
        hand.add_cards(deck.deal(3))
        expect(hand.cards).to have(3).cards
        expect(hand.cards[0]).to be_a(Card)
      end

      it 'adds cards to a set of cards' do
        hand.add_cards(deck.deal(2))
        expect(hand.cards).to have(4).cards
      end
    end
  end

  describe '#display' do
    context 'when called' do
      it 'displays the contents of the hand' do
        expected = "5♥".colorize(color: :red, background: :white) + " " + "7♣".colorize(color: :black, background: :white)
        expect(hand.display).to eq(expected)
      end
    end
  end

  describe '#discard' do
    context 'when passed an array of indices' do
      it 'deletes those cards from the hand' do
        hand.discard([1])
        expect(hand.cards).to eq([card1])
      end

      it 'raises error if passed index is out of range' do
        expect { hand.discard([2]) }.to raise_error(RuntimeError)
      end
    end
  end

  describe '#name' do
    let(:royal_flush) { [14, :hearts, 13, :hearts, 12, :hearts, 11, :hearts, 10, :hearts] }
    let(:straight_flush) { [8, :spades, 7, :spades, 6, :spades, 5, :spades, 4, :spades] }
    let(:four_of_a_kind) { [8, :spades, 8, :hearts, 8, :diamonds, 8, :clubs, 4, :spades] }
    let(:full_house) { [8, :spades, 8, :hearts, 8, :diamonds, 7, :clubs, 7, :spades] }
    let(:flush) { [8, :spades, 7, :spades, 6, :spades, 2, :spades, 4, :spades] }
    let(:straight) { [8, :spades, 7, :clubs, 6, :spades, 5, :spades, 4, :spades] }
    let(:three_of_a_kind) { [8, :spades, 8, :hearts, 8, :diamonds, 5, :spades, 4, :spades] }
    let(:two_pair) { [8, :spades, 8, :hearts, 7, :diamonds, 7, :spades, 4, :spades] }
    let(:one_pair) { [8, :spades, 8, :hearts, 5, :diamonds, 7, :spades, 4, :spades] }

    context 'when passed a hand' do
      it 'recognizes royal flush' do
        hand = create_hand(royal_flush)
        expect(hand.hand_name).to eq("Royal Flush")
      end

      it 'recognizes straight flush' do
        hand = create_hand(straight_flush)
        expect(hand.hand_name).to eq("Straight Flush")
      end

      it 'recognizes four of a kind' do
        hand = create_hand(four_of_a_kind)
        expect(hand.hand_name).to eq("Four of a Kind")
      end

      it 'recognizes full house' do
        hand = create_hand(full_house)
        expect(hand.hand_name).to eq("Full House")
      end

      it 'recognizes flush' do
        hand = create_hand(flush)
        expect(hand.hand_name).to eq("Flush")
      end

      it 'recognizes straight' do
        hand = create_hand(straight)
        expect(hand.hand_name).to eq("Straight")
      end

      it 'recognizes three of a kind' do
        hand = create_hand(three_of_a_kind)
        expect(hand.hand_name).to eq("Three of a Kind")
      end

      it 'recognizes two pair' do
        hand = create_hand(two_pair)
        expect(hand.hand_name).to eq("Two Pair")
      end

      it 'recognizes one pair' do
        hand = create_hand(one_pair)
        expect(hand.hand_name).to eq("One Pair")
      end

    end
  end
end

RSpec.describe Player do
  subject(:player) {Player.new("Bob", 50)}
  let (:card1) { Card.new(5, :hearts) }
  let (:card2) { Card.new(7, :clubs) }
  let (:card3) { Card.new(11, :clubs) }


  before(:each) do
    player.new_hand([card1, card2])
  end

  describe '#new_hand' do
    context "when passed an array of cards" do
      it "creates a new hand" do
        expect(player.hand.cards).to eq([card1, card2])
        player.new_hand([card1, card3])
        expect(player.hand.cards).to eq([card1, card3])
      end
    end
  end

  describe '#display_hand' do
    context 'when called' do
      it 'displays hand' do
        expected = "5♥".colorize(color: :red, background: :white) + " " + "7♣".colorize(color: :black, background: :white)
        expect(player.display_hand).to eq(expected)
      end
    end
  end

  describe 'change_purse' do
    context 'when called with a number' do
      it 'adds or subtracts money from the purse' do
        player.purse = 50
        player.change_purse(20)
        expect(player.purse).to eq(70)
      end
    end
  end

  describe '#take_cards' do
    context 'when called with an array of cards' do
      it 'adds those cards to the hand' do
        player.take_cards([card3])
        expect(player.hand.cards).to eq([card1, card2, card3])
      end
    end
  end
end

RSpec.describe Game do
  let(:player1) { Player.new("Bob", 50) }
  let(:player2) { Player.new("Alice", 50) }
  let(:player3) { Player.new("Sue", 50) }
  let(:four_of_a_kind) { [8, :spades, 8, :hearts, 8, :diamonds, 8, :clubs, 4, :spades] }
  let(:four_of_a_kind2) { [9, :spades, 9, :hearts, 9, :diamonds, 9, :clubs, 4, :spades] }
  let(:full_house) { [8, :spades, 8, :hearts, 8, :diamonds, 7, :clubs, 7, :spades] }
  let(:flush) { [8, :spades, 7, :spades, 6, :spades, 2, :spades, 4, :spades] }
  let(:flush2) { [9, :spades, 7, :spades, 6, :spades, 2, :spades, 4, :spades] }
  subject(:game) {Game.new([player1, player2, player3])}

  describe '#initialize' do
    context 'when initialized with an array of players' do
      it 'sets the players' do
        expect(game.players).to eq([player1, player2, player3])
      end
    end
  end

  describe '#start_round' do
    context 'when starting the round' do
      it 'creates a new deck' do
        game.start_round
        expect(game.deck.cards).to have(52).cards
        game.deck.deal(5)
        game.start_round
        expect(game.deck.cards).to have(52).cards
      end

      it 'starts with no folded players' do
        player1.folded = true
        game.start_round
        expect(player1).to_not be_folded
      end

      it 'increments starting player' do
        game.start_round
        expect(game.players).to eq([player3, player1, player2])
      end
    end
  end

  describe '#deal_hands' do
    context 'at the beginning of the game' do
      it 'deals 5 cards to each player' do
        game.start_round
        game.deal_hands
        expect(game.players.map { |player| player.hand.cards.length }.all? { |card_length| card_length == 5 }).to be_truthy
      end
    end
  end

  describe '#determine_winner' do
    before do
      player1.hand = create_hand(four_of_a_kind)
      player2.hand = create_hand(full_house)
      player3.hand = create_hand(flush)
    end

    context 'when players have hands of different ranks' do
      it 'selects the winning player' do
        expect(game.determine_winner[0]).to eq(player1)
      end
    end

    context 'when players have tied hands' do
      it 'ranks the tied hands' do
        player3.hand = create_hand(four_of_a_kind2)
        expect(game.determine_winner[0]).to eq(player3)
      end
    end

    # context 'when players have exactly tied hands' do
    #   it 'returns both of them' do

  end
end
