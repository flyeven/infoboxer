# encoding: utf-8
require 'procme'
require 'backports/2.1.0/array/to_h'
#require 'backports/2.2.0/object/itself' Y U NO???

# Main client module for entire infoboxer functionality. If you're lucky,
# there's no other classes/modules you need to instantiate or call
# directly. You just do:
#
# ```ruby
# Infoboxer.wp.get('List of radio telescopes')
# # or 
# Infoboxer.wikiquote.get('Vonnegut')
# ```
# ...and have fully navigable Wiki information.
#
# Please read [wiki](http://github.com/molybdenum-99/infoboxer/wiki)
# for extensive [showcases](https://github.com/molybdenum-99/infoboxer/wiki/Showcase)
# and usage recommendations.
#
# Here's main components list, which also can serve as a TOC for
# Infoboxer's functionality (we suggest to read their docs in this order):
#
# * {Tree} -- nodes, of which Wikipedia AST is consisting; you'll be
#   interested in basic {Tree::Node} functionality, as well as node
#   classes list (which is useful for navigation);
# * {Navigation} -- how to navigate the tree you have, basic way
#   (children, parents, siblings) and hi-level shortcuts way (like
#   all unnumbered list items in second level-3 section);
# * {Templates} -- the most advanced data extraction from wikipedia definitely
#   needs your undestanding of this (rather complicated) topic.
#
# You also may be interested in (though may be never need to use them directly):
#
# * {MediaWiki} client class;
# * {Parser} -- which, you know, parses.
#
module Infoboxer
  private # hiding constants from YARD

  WIKIA_API_URL = 'http://%s.wikia.com/api.php'

  WIKIMEDIA_PROJECTS = {
    wikipedia: 'wikipedia.org',
    wikivoyage: 'wikivoyage.org',
    wikiquote: 'wikiquote.org',
    wiktionary: 'wiktionary.org',
    wikibooks: 'wikibooks.org',
    wikinews: 'wikinews.org',
    wikiversity: 'wikiversity.org',
    wikisource: 'wikisource.org'
  }

  WIKIMEDIA_COMMONS = {
    commons: 'commons.wikimedia.org',
    species: 'species.wikimedia.org',
  }

  class << self

    # Default method for creating MediaWiki API client.
    #
    # @param api_url should be URL of api.php for your MediaWiki
    # @param options list of options.
    #   The only recognized option for now, though, is
    #   * `:user_agent` (also aliased as `:ua`) -- custom User-Agent header.
    # @return [MediaWiki] an instance of API client, which you can
    #   further use like this:
    #
    #   ```ruby
    #   Infoboxer.wiki('some_url').get('Some page title')
    #   ```
    def wiki(api_url, options = {})
      MediaWiki.new(api_url, options || {})
    end

    # @!method wikipedia(lang = 'en', options = {})
    # Shortcut for creating Wikipedia client.
    #
    # @param lang two-character code for language version
    # @param options (see #wiki for list of options)
    # @return [MediaWiki]
    
    # @!method commons(options = {})
    # Shortcut for creating [WikiMedia Commons](https://commons.wikimedia.org/) client.
    #
    # @param options (see #wiki for list of options)
    # @return [MediaWiki]
    
    # @!method wikibooks(lang = 'en', options = {})
    # Shortcut for creating [Wikibooks](https://en.wikibooks.org/) client.
    # See {wikipedia} for params explanation.
    # @return [MediaWiki]

    # @!method wikiquote(lang = 'en', options = {})
    # Shortcut for creating [Wikiquote](https://en.wikiquote.org/) client.
    # See {wikipedia} for params explanation.
    # @return [MediaWiki]

    # @!method wikiversity(lang = 'en', options = {})
    # Shortcut for creating [Wikiversity](https://en.wikiversity.org/) client.
    # See {wikipedia} for params explanation.
    # @return [MediaWiki]

    # @!method wikisource(lang = 'en', options = {})
    # Shortcut for creating [Wikisource](https://en.wikisource.org/) client.
    # See {wikipedia} for params explanation.
    # @return [MediaWiki]

    # @!method wikivoyage(lang = 'en', options = {})
    # Shortcut for creating [Wikivoyage](http://wikivoyage.org) client.
    # See {wikipedia} for params explanation.
    # @return [MediaWiki]

    # @!method wikinews(lang = 'en', options = {})
    # Shortcut for creating [Wikinews](https://en.wikinews.org/) client.
    # See {wikipedia} for params explanation.
    # @return [MediaWiki]

    # @!method species(options = {})
    # Shortcut for creating [Wikispecies](https://species.wikimedia.org/) client.
    #
    # @param options (see #wiki for list of options)
    # @return [MediaWiki]
    
    # @!method wiktionary(lang = 'en', options = {})
    # Shortcut for creating [Wiktionary](https://en.wiktionary.org/) client.
    # See {wikipedia} for params explanation.
    # @return [MediaWiki]

    WIKIMEDIA_PROJECTS.each do |name, domain|
      define_method name do |lang = 'en', options = {}|
        if lang.is_a?(Hash)
          lang, options = 'en', lang
        end

        wiki("https://#{lang}.#{domain}/w/api.php", options)
      end
    end

    alias_method :wp, :wikipedia

    WIKIMEDIA_COMMONS.each do |name, domain|
      define_method name do |options = {}|
        wiki("https://#{domain}/w/api.php", options)
      end
    end

    # Performs request to wikia.com wikis.
    #
    # @overload wikia(*domains)
    #   @param *domains list of domains to merge, like this:
    #   
    #     ```ruby
    #     Infoboxer.wikia('tardis') # looks at tardis.wikia.com
    #     Infoboxer.wikia('tardis', 'ru') # looks in Russian version, ru.tardis.wikia.com
    #     ```
    #     If you are surprised by "reversing" list of subdomains, think of
    #     it as of chain of refinements (looking in "tardis" wiki, its "ru" 
    #     version, specifically).
    #
    # @overload wikia(*domains, options)
    #   @param *domains same as above
    #   @param options just last of params, if it is hash
    #     (see {wiki} for list of options)
    #
    # @return [MediaWiki]
    def wikia(*domains)
      options = domains.last.is_a?(Hash) ? domains.pop : {}
      wiki(WIKIA_API_URL % domains.reverse.join('.'), options)
    end

    # Sets user agent string globally. Default user agent is 
    # {MediaWiki::UA}.
    #
    # User agent can also be rewriten as an option to {wiki} method (and
    # its shortcuts like {wikipedia}), or by using {MediaWiki#initialize}
    # explicitly.
    #
    def user_agent=(ua)
      MediaWiki.user_agent = ua
    end
  end
end

require_relative 'infoboxer/version'
require_relative 'infoboxer/core_ext'

require_relative 'infoboxer/tree'
require_relative 'infoboxer/parser'
require_relative 'infoboxer/navigation'
require_relative 'infoboxer/templates'

require_relative 'infoboxer/media_wiki'

require_relative 'infoboxer/definitions/en.wikipedia.org'
