require "delegate"

# Propshaft only logs a warning when a url() in a stylesheet or a JavaScript
# file points at an asset it cannot find: precompilation still succeeds and the
# reference 404s in production instead. Collect those warnings and fail the
# build on them, so CI and the image build catch a broken path before a deploy
# does.
module UnresolvedAssetReferences
  WARNING = /\AUnable to resolve /

  class Collector < SimpleDelegator
    def initialize(logger, references)
      super(logger)
      @references = references
    end

    def warn(message = nil, &block)
      message ||= block&.call
      @references << message if message.to_s.match?(WARNING)
      super(message)
    end
  end

  class << self
    def references
      @references ||= []
    end

    def watch
      Propshaft.logger = Collector.new(Propshaft.logger, references)
    end
  end
end

namespace :assets do
  task :watch_unresolved_references do
    UnresolvedAssetReferences.watch
  end
end

Rake::Task["assets:precompile"].enhance([ "assets:watch_unresolved_references" ]) do
  references = UnresolvedAssetReferences.references

  if references.any?
    abort <<~MESSAGE

      Asset precompilation left #{references.size} reference#{"s" if references.size > 1} unresolved:

      #{references.map { |reference| "  #{reference}" }.join("\n")}

      Each one 404s in production. Fix the path, or add the missing file.
    MESSAGE
  end
end
