require 'csv'

submissions = gets(p).scan(/<h4.*?<\/app-submission-game>/m)

def user2runner(user, user_label)
  "#{user_label} (#{user})"
end

CSV.instance($stdout, quote_char: '"', force_quotes: true){|csv_out|
  csv_out << ["runner","game_name","game_description","game_console","game_ratio","category_name","category_description","category_type","category_estimate","category_video","status","availabilities"
]
  submissions.each{|submission|
    /href="\/user\/(?<user>.+?)"\starget="_self">(?<user_label>.+?)<\/a>/ =~ submission
    submission_rest = $'
    runner = user2runner(user, user_label)
    submission_rest.scan(/<app-submission-game.*?<\/app-submission-game>/m){|game|
      /has-text-light\"> (?<game_name>[^<>]+) - (?<game_console>.+?)<
      .*?
      <article[^>]+>(?<game_description>.*?)<\/article>/mx =~ game
      game_rest = $'
      game_rest.scan(/<app-submission-category.*?<\/app-submission-category>/m){|category|
        /<app-submission-category.*?<p[^>]+> (?<category_name>[^<>]+) \((?<category_type>.+?)\)
        .*?
        (?<category_estimate>[^<>]+?)<\/time>
        .*?
        <a [^>]+href=\"(?<category_video>.*?)"
        (?<category_rest>.*?)
        <article[^>]+>(?<category_description>.*?)<\/article>
        /xm =~ category
        if category_rest.include?("With:")
          pairs = []
          pairs << [user2runner(user, user_label), category_video]
          category_rest.scan(/href="\/user\/(.+?)"\starget="_self">(.+?)<\/a>
          .*?
          <a [^>]+href=\"(.*?)"/mx){|with_user, with_user_label, with_category_video|
            pairs << [user2runner(with_user, with_user_label), with_category_video]
          }
          category_video = pairs.map{|with_runner, with_category_video| "#{with_runner}: #{with_category_video}" }.join(' - ')
          runner = pairs.map(&:first).join(', ')
        end
        /class="is-pulled-right">\s*(?<status>.*?)\s*<\/p>/ =~ category_rest
        status ||= 'To Do'
        csv_out << [runner, game_name, game_description, game_console, "?", category_name, category_description, category_type, category_estimate, category_video, status]
      }
    }
  }
}

__END__
