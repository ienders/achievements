# An Abstract, Redis-Backed Achievements Engine
require 'rubygems'
require 'redis'

module Achievements
  module AgentIncludes
    # Convenience methods for instantiating an engine and adding achievements
    def self.included(base)
      base.extend IncludeClassMethods
    end
  
    # Convenience Class Methods for ActiveRecord::Base like User Classes
    module IncludeClassMethods
      # Instantiates the AchievementEngine and sets
      # the contexts, which instantiate context specific counters.  Use
      # only once.
      # 
      # achieveable [:context1,:context2]
      #
      def achievable(contexts)
        @engine = Engine.new(contexts)
      end

      # Convenience method for access to achievements engine
      def engine
        @engine
      end
      
      # Convenience method for access to redis connection
      def redis
        @engine.redis
      end
      
      # Binds an achievement with a specific counter threshold. Use as
      # many as you'd like.
      #
      # bind :context, :name, threshold
      #
      def bind(context, name, threshold)
        @engine.bind(context,name,threshold)
      end

      # Alternately, bind an entire array of achievement objects.  To
      # use this, achievements must respond to the context, name, and
      # threshold methods.
      #
      # For example, when using with rails:
      #
      # bind_all Achievement.all
      #
      def bind_all(object_array)
        object_array.each do |object|
          @engine.bind object.context, object.name, object.threshold
        end
      end

      # Trigger a bound achievement method.  Since this is a class
      # level method, you must include the agent id along with the
      # method call
      #
      # trigger agent_id, context, name
      #
      def trigger(agent_id, context, name)
        @engine.trigger agent_id, context, name
      end
    end

    # Agent instance methods

    # Agent instance level achievement trigger.  Automatically sends
    # agent id along with context and name to the AchievementEngine
    def trigger(context,name)
      self.class.engine.trigger @id, context, name
    end
  end
  
  module AchievementIncludes
    # Convenience methods
    def self.included(base)
      base.extend IncludeClassMethods
    end

    module IncludeClassMethods
      # Update the threshold for the AchievementEngine achievement
      # that matches context, achievement, and sets threshold to new_threshold
      def update_threshold(context, achievement, new_threshold)
        # find achievement and update threshold
      end 
    end
  end
  
  # Achivements Interface Class
  class Engine
    attr_accessor :redis
    attr_accessor :achievements
    attr_accessor :contexts
    
    def initialize(contexts)
      connect if @redis.nil?
      @contexts = contexts
      @achievements = []
    end
    
    def connect
      @redis ||= Redis.connect
    end
    
    def bind(context,name,threshold)
      if achievement = Achievement.new(context,name,threshold)
        @achievements << achievement
      end
    end

    # Increment counter
    # Check threshold
    # Output results
    #
    # context, agent_id, name
    def trigger(context, agent_id, name)
      # Increment counter
      counter = Counter.new(context,agent_id,name)
      incr counter
    end

    # incr key
    def incr(counter)
      @redis.incr counter
    end
    
    # decr key
    def decr(counter)
      @redis.decr counter
    end
    
    ## Class Methods

   
  end
  
  # Achievement, basis of counters
  class Achievement
    attr_accessor :name
    attr_accessor :threshold
    attr_accessor :context
  
    def initialize(context, name, threshold)
      @name = name
      @threshold = threshold
      @context = context
    end
  end
  
  # Counter class is really a Redis key factory.  Responsibility of
  # communicating with Redis belongs with the engine.
  class Counter
    attr_accessor :context
    attr_accessor :agent_id
    attr_accessor :key

    def initialize(context, agent_id, name)
      @key = "#{context}:agent:#{agent_id}:#{name}"
    end

  end
end