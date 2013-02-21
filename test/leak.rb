# -*- encoding : utf-8 -*-
require 'map'

##
#
  gc =
    lambda do
      10.times{ GC.start }
    end

  leak =
    lambda do
      100.times do
        m = Map.new

        1000.times do |i|
          m[rand.to_s] = rand
        end
      end

      gc.call()
    end

##
#


  leak.call()
  before = Process.size


  leak.call()
  after = Process.size

  delta = [after.first - before.first, after.last - before.last]

  p :before => before 
  p :after => after 
  p :delta => delta


##
#
  BEGIN {

    module Process
      def self.size pid = Process.pid 
        stdout = `ps wwwux -p #{ pid }`.split(%r/\n/)
        vsize, rsize = stdout.last.split(%r/\s+/)[4,2].map{|i| i.to_i}
      end

      def self.vsize
        size.first.to_i
      end

      def self.rsize
        size.last.to_i
      end
    end

  }
