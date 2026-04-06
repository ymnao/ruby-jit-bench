require_relative "../lib/bench_helper"

class Dog;    def speak = "woof";  end
class Cat;    def speak = "meow";  end
class Bird;   def speak = "tweet"; end
class Cow;    def speak = "moo";   end
class Sheep;  def speak = "baa";   end

ANIMALS = [Dog, Cat, Bird, Cow, Sheep].map(&:new).freeze

def dispatch(animals)
  animals.each { |a| a.speak }
end

run_bench("Polymorphic", n: 500_000) { dispatch(ANIMALS) }
