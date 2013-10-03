SimpleNavigation::Configuration.run do |navigation|
  # Specify a custom renderer if needed.
  # The default renderer is SimpleNavigation::Renderer::List which renders HTML lists.
  # The renderer can also be specified as option in the render_navigation call.
  # navigation.renderer = Your::Custom::Renderer

  # Specify the class that will be applied to active navigation items. Defaults to 'selected'
  # navigation.selected_class = 'your_selected_class'
  navigation.selected_class = 'active'

  # Specify the class that will be applied to the current leaf of
  # active navigation items. Defaults to 'simple-navigation-active-leaf'
  # navigation.active_leaf_class = 'your_active_leaf_class'

  # Item keys are normally added to list items as id.
  # This setting turns that off
  # navigation.autogenerate_item_ids = false

  # You can override the default logic that is used to autogenerate the item ids.
  # To do this, define a Proc which takes the key of the current item as argument.
  # The example below would add a prefix to each key.
  # navigation.id_generator = Proc.new {|key| "my-prefix-#{key}"}

  # If you need to add custom html around item names, you can define a proc that will be called with the name you pass in to the navigation.
  # The example below shows how to wrap items spans.
  # navigation.name_generator = Proc.new {|name| "<span>#{name}</span>"}

  # The auto highlight feature is turned on by default.
  # This turns it off globally (for the whole plugin)
  # navigation.auto_highlight = false
  navigation.items do |primary|
    primary.item :dashboard, 'Dashboard', root_path,  highlights_on: %r(/$)
    primary.item :events, 'Events', events_path, highlights_on: %r(/events), :if => Proc.new { can?(:index, Event) }
    primary.item :tasks, 'Tasks', mine_tasks_path, highlights_on: %r(/tasks), :if => Proc.new { can?(:index_my, Task) || can?(:index_team, Task) } do |secondary|
      secondary.item :mine_tasks, 'My Tasks', mine_tasks_path, highlights_on: %r(/tasks/mine), :if => Proc.new { can?(:index_my, Task) }
      secondary.item :team_tasks, 'Team Tasks', my_teams_tasks_path, highlights_on: %r(/tasks/my_teams), :if => Proc.new { can?(:index_team, Task) }
    end
    primary.item :venues, 'Venues', venues_path, highlights_on: %r(/research) do |secondary|
      secondary.item :venues, 'Venues', venues_path, highlights_on: %r(/research/venues)
    end

    options = []
    options.push([:event_data, 'Event Data', results_event_data_path, highlights_on: %r(/results/event_data) ]) if can?(:index_results, EventData)
    options.push([:comments, 'Comments', results_comments_path, highlights_on: %r(/results/comments) ]) if can?(:index_results, Comment)
    options.push([:photos, 'Photos', results_photos_path, highlights_on: %r(/results/photos) ]) if can?(:index_photo_results, AttachedAsset)
    options.push([:expenses, 'Expenses', results_expenses_path, highlights_on: %r(/results/expenses)]) if can?(:index_results, EventExpense)
    options.push([:surveys, 'Surveys', results_surveys_path, highlights_on: %r(/results/surveys)]) if can?(:index_results, Survey)

    unless options.empty?
      primary.item :results, 'Results', options.first[2], highlights_on: %r(/results) do |secondary|
        options.each {|option| secondary.item *option }
      end
    end

    primary.item :analysis, 'Analysis', analysis_campaigns_report_path,  highlights_on: %r(/analysis) do |secondary|
      # secondary.item :snapshot_report, 'Snapshot Report', '#', highlights_on: %r(/analysis/snapshot_report)
      secondary.item :campaigns_report, 'Campaigns Report', analysis_campaigns_report_path, highlights_on: %r(/analysis/campaigns_report), :if => Proc.new { can?(:show_analysis, CompanyUser) }
      secondary.item :staff_performance, 'Staff Performance', analysis_staff_report_path, highlights_on: %r(/analysis/staff_report), :if => Proc.new { can?(:show_analysis, Campaign) }
    end
  end
end