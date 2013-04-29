class Player
  WELL_RESTED = 20
  NEEDS_REST = 5
  def play_turn(warrior)
    @warrior = warrior
    @old_health ||= warrior.health
    @resting ||= false

    puts warrior.listen

    unless rest_if_needed!
      if count_nearby{ |dir| @warrior.feel(dir).enemy? } > 1
        act_nearby! do |dir|
          if @warrior.feel(dir).enemy?
            @warrior.bind!(dir)
            return true
          end
        end

      elsif count_nearby{ |dir| @warrior.feel(dir).captive? } > 0 &&
            count_nearby{ |dir| @warrior.feel(dir).enemy? } == 0
        act_nearby! do |dir|
          if @warrior.feel(dir).captive?
            @warrior.rescue!(dir)
            return true
          end
        end
      else
        fight_to_stairs! unless act_nearby! do |dir|
          if @warrior.feel(dir).enemy?
            @warrior.attack!(dir)
            return true
          end
        end

      end
    end
    @old_health = warrior.health
  end

  def dir_of_stairs
    @warrior.direction_of_stairs
  end

  def walk_toward_stairs!
    @warrior.walk!(dir_of_stairs)
  end

  def attack_toward_stairs!
    @warrior.attack!(dir_of_stairs)
  end

  def fight_to_stairs!
    if @warrior.feel(dir_of_stairs).enemy?
      attack_toward_stairs!
    else
      walk_toward_stairs!
    end
  end

  def fight_nearby!
    nearby = feel_enemy_all_around
    if nearby
      @warrior.attack!(nearby)
      return true
    end
    return false
  end

  def feel_enemy_all_around
    on_each_dir do |dir|
      return dir if @warrior.feel(dir).enemy?
    end
    nil
  end

  def rest_if_needed!
    if @resting
      if @warrior.health < WELL_RESTED
        @warrior.rest!
      else
        @resting = false
        advance_from_retreat!
      end
      return true

    elsif @warrior.health < NEEDS_REST
      if @old_health > @warrior.health
        unless retreat!
          puts "No escape!"
          return false
        end
      else
        @warrior.rest!
      end
      @resting = true
      return true
    end
    @resting = false
    false
  end

  def retreat!
    on_each_dir do |dir|
      if @warrior.feel(dir).empty?
        @retreated_dir = dir
        @warrior.walk!(dir)
        return true
      end
    end
    false
  end

  def advance_from_retreat!
    @warrior.walk!(opposite_dir(@retreated_dir) || :forward)
    @retreated_dir = nil
  end

  def count_nearby
    things = 0
    [:forward, :backward, :left, :right].each do |dir|
      things+=1 if yield(dir)
    end
    return things
  end

  def act_nearby!
    on_each_dir do |dir|
      next if @warrior.feel(dir).empty?
      yield dir
    end
    return false
  end

  def on_each_dir
    [:forward, :backward, :left, :right].each do |dir|
      yield dir
    end
  end

  def opposite_dir(dir)
    case dir
    when :forward
      :backward
    when :backward
      :forward
    when :left
      :right
    when :right
      :left
    end
  end
end
