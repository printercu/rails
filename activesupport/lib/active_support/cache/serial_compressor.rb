# frozen_string_literal: true

require "zlib"
require "concurrent/executor/cached_thread_pool"

module ActiveSupport
  module Cache
    # Basic compressor implementation which dumps values using Marshal and Zlib.
    module SerialCompressor
      extend self

      # Dumps value into string. Returns nil if `:compress_threshold` option
      # is set and serialized value is less than given value.
      def dump(value, compress_threshold: nil)
        serialized = Marshal.dump(value)
        return if compress_threshold && serialized.bytesize < compress_threshold
        deflate(serialized)
      end

      def load(value)
        Marshal.load(inflate(value))
      end

      def deflate(value)
        Zlib.deflate(value)
      end

      def inflate(value)
        Zlib.inflate(value)
      end
    end
  end
end
