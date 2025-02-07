#!/usr/bin/env bash
# setting the locale, some users have issues with different locales, this forces the correct one
export LC_ALL=en_US.UTF-8

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $current_dir/utils.sh

main() {
  # set configuration option variables
  terraform_label=$(get_tmux_option "@kanagawa-terraform-label" "")
  show_fahrenheit=$(get_tmux_option "@kanagawa-show-fahrenheit" true)
  show_location=$(get_tmux_option "@kanagawa-show-location" true)
  fixed_location=$(get_tmux_option "@kanagawa-fixed-location")
  show_powerline=$(get_tmux_option "@kanagawa-show-powerline" false)
  show_flags=$(get_tmux_option "@kanagawa-show-flags" false)
  show_left_icon=$(get_tmux_option "@kanagawa-show-left-icon" smiley)
  show_left_icon_padding=$(get_tmux_option "@kanagawa-left-icon-padding" 1)
  show_military=$(get_tmux_option "@kanagawa-military-time" false)
  show_timezone=$(get_tmux_option "@kanagawa-show-timezone" true)
  show_left_sep=$(get_tmux_option "@kanagawa-show-left-sep" )
  show_right_sep=$(get_tmux_option "@kanagawa-show-right-sep" )
  show_border_contrast=$(get_tmux_option "@kanagawa-border-contrast" false)
  show_day_month=$(get_tmux_option "@kanagawa-day-month" false)
  show_refresh=$(get_tmux_option "@kanagawa-refresh-rate" 5)
  show_synchronize_panes_label=$(get_tmux_option "@kanagawa-synchronize-panes-label" "Sync")
  time_format=$(get_tmux_option "@kanagawa-time-format" "")
  show_kubernetes_context_label=$(get_tmux_option "@kanagawa-kubernetes-context-label" "")
  IFS=' ' read -r -a plugins <<<$(get_tmux_option "@kanagawa-plugins" "battery network weather")
  show_empty_plugins=$(get_tmux_option "@kanagawa-show-empty-plugins" true)

  # kanagawa Color Pallette
  white='#C8C093'
  yellow='#c4b28a'
  cyan='#8ea4a2'
  green='#8a9a7b'
  red='#c4746e'
  gray='#181616'
  dark_gray='#0d0c0c'
  magenta='#c4746e'
  blue='#8ba4b0'
  medium_gray='#333333' # My own choice

  light_purple='#666666' # Not translated

  # Handle left icon configuration
  case $show_left_icon in
  smiley)
    left_icon="☺"
    ;;
  session)
    left_icon="#S"
    ;;
  window)
    left_icon="#W"
    ;;
  *)
    left_icon=$show_left_icon
    ;;
  esac

  # Handle left icon padding
  padding=""
  if [ "$show_left_icon_padding" -gt "0" ]; then
    padding="$(printf '%*s' $show_left_icon_padding)"
  fi
  left_icon="$left_icon$padding"

  # Handle powerline option
  if $show_powerline; then
    right_sep="$show_right_sep"
    left_sep="$show_left_sep"
  fi

  # Set timezone unless hidden by configuration
  case $show_timezone in
  false)
    timezone=""
    ;;
  true)
    timezone="#(date +%Z)"
    ;;
  esac

  case $show_flags in
  false)
    flags=""
    current_flags=""
    ;;
  true)
    flags="#{?window_flags,#[fg=${medium_gray}]#{window_flags},}"
    current_flags="#{?window_flags,#[fg=${light_purple}]#{window_flags},}"
    ;;
  esac

  # sets refresh interval to every 5 seconds
  tmux set-option -g status-interval $show_refresh

  # set the prefix + t time format
  if $show_military; then
    tmux set-option -g clock-mode-style 24
  else
    tmux set-option -g clock-mode-style 12
  fi

  # set length
  tmux set-option -g status-left-length 100
  tmux set-option -g status-right-length 100

  # pane border styling
  if $show_border_contrast; then
    tmux set-option -g pane-active-border-style "fg=${light_purple}"
  else
    tmux set-option -g pane-active-border-style "fg=${medium_gray}"
  fi
  tmux set-option -g pane-border-style "fg=${gray}"

  # message styling
  tmux set-option -g message-style "bg=default,fg=${white}"

  # status bar
  tmux set-option -g status-style "bg=${gray},fg=${white}"

  # Status left
  if $show_powerline; then
    tmux set-option -g status-left "#[bg=${green},fg=${dark_gray}]#{?client_prefix,#[bg=${yellow}],} ${left_icon} #[fg=${green},bg=${gray}]#{?client_prefix,#[fg=${yellow}],}${left_sep}"
    powerbg=${gray}
  else
    tmux set-option -g status-left "#[bg=${green},fg=${dark_gray}]#{?client_prefix,#[bg=${yellow}],} ${left_icon}"
  fi

  # Status right
  tmux set-option -g status-right ""

  for plugin in "${plugins[@]}"; do

    if case $plugin in custom:*) true ;; *) false ;; esac then
      script=${plugin#"custom:"}
      if [[ -x "${current_dir}/${script}" ]]; then
        IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-custom-plugin-colors" "cyan dark_gray")
        script="#($current_dir/${script})"
      else
        colors[0]="red"
        colors[1]="dark_gray"
        script="${script} not found!"
      fi

    elif [ $plugin = "cwd" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-cwd-colors" "dark_gray white")
      tmux set-option -g status-right-length 250
      script="#($current_dir/cwd.sh)"

    elif [ $plugin = "git" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-git-colors" "green dark_gray")
      tmux set-option -g status-right-length 250
      script="#($current_dir/git.sh)"

    elif [ $plugin = "hg" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-hg-colors" "green dark_gray")
      tmux set-option -g status-right-length 250
      script="#($current_dir/hg.sh)"

    elif [ $plugin = "battery" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-battery-colors" "blue dark_gray")
      script="#($current_dir/battery.sh)"

    elif [ $plugin = "gpu-usage" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-gpu-usage-colors" "blue dark_gray")
      script="#($current_dir/gpu_usage.sh)"

    elif [ $plugin = "gpu-ram-usage" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-gpu-ram-usage-colors" "cyan dark_gray")
      script="#($current_dir/gpu_ram_info.sh)"

    elif [ $plugin = "gpu-power-draw" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-gpu-power-draw-colors" "green dark_gray")
      script="#($current_dir/gpu_power.sh)"

    elif [ $plugin = "cpu-usage" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-cpu-usage-colors" "magenta dark_gray")
      script="#($current_dir/cpu_info.sh)"

    elif [ $plugin = "ram-usage" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-ram-usage-colors" "cyan dark_gray")
      script="#($current_dir/ram_info.sh)"

    elif [ $plugin = "tmux-ram-usage" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-tmux-ram-usage-colors" "cyan dark_gray")
      script="#($current_dir/tmux_ram_info.sh)"

    elif [ $plugin = "network" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-network-colors" "cyan dark_gray")
      script="#($current_dir/network.sh)"

    elif [ $plugin = "network-bandwidth" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-network-bandwidth-colors" "cyan dark_gray")
      tmux set-option -g status-right-length 250
      script="#($current_dir/network_bandwidth.sh)"

    elif [ $plugin = "network-ping" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-network-ping-colors" "cyan dark_gray")
      script="#($current_dir/network_ping.sh)"

    elif [ $plugin = "network-vpn" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-network-vpn-colors" "cyan dark_gray")
      script="#($current_dir/network_vpn.sh)"

    elif [ $plugin = "attached-clients" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-attached-clients-colors" "cyan dark_gray")
      script="#($current_dir/attached_clients.sh)"

    elif [ $plugin = "spotify-tui" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-spotify-tui-colors" "green dark_gray")
      script="#($current_dir/spotify-tui.sh)"

    elif [ $plugin = "kubernetes-context" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-kubernetes-context-colors" "cyan dark_gray")
      script="#($current_dir/kubernetes_context.sh $show_kubernetes_context_label)"

    elif [ $plugin = "terraform" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-terraform-colors" "light_purple dark_gray")
      script="#($current_dir/terraform.sh $terraform_label)"

    elif [ $plugin = "continuum" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-continuum-colors" "cyan dark_gray")
      script="#($current_dir/continuum.sh)"

    elif [ $plugin = "weather" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-weather-colors" "magenta dark_gray")
      script="#($current_dir/weather_wrapper.sh $show_fahrenheit $show_location $fixed_location)"

    elif [ $plugin = "time" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-time-colors" "medium_gray white")
      if [ -n "$time_format" ]; then
        script=${time_format}
      else
        if $show_day_month && $show_military; then # military time and dd/mm
          script="%a %d/%m %R ${timezone} "
        elif $show_military; then # only military time
          script="%a %m/%d %R ${timezone} "
        elif $show_day_month; then # only dd/mm
          script="%a %d/%m %I:%M %p ${timezone} "
        else
          script="%a %m/%d %I:%M %p ${timezone} "
        fi
      fi
    elif [ $plugin = "synchronize-panes" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@kanagawa-synchronize-panes-colors" "cyan dark_gray")
      script="#($current_dir/synchronize_panes.sh $show_synchronize_panes_label)"
    else
      continue
    fi

    if $show_powerline; then
      if $show_empty_plugins; then
        tmux set-option -ga status-right "#[fg=${!colors[0]},bg=${powerbg},nobold,nounderscore,noitalics]${right_sep}#[fg=${!colors[1]},bg=${!colors[0]}] $script "
      else
        tmux set-option -ga status-right "#{?#{==:$script,},,#[fg=${!colors[0]},nobold,nounderscore,noitalics]${right_sep}#[fg=${!colors[1]},bg=${!colors[0]}] $script }"
      fi
      powerbg=${!colors[0]}
    else
      if $show_empty_plugins; then
        tmux set-option -ga status-right "#[fg=${!colors[1]},bg=${!colors[0]}] $script "
      else
        tmux set-option -ga status-right "#{?#{==:$script,},,#[fg=${!colors[1]},bg=${!colors[0]}] $script }"
      fi
    fi
  done

  # Window option
  if $show_powerline; then
    tmux set-window-option -g window-status-current-format "#[fg=${gray},bg=${medium_gray}]${left_sep}#[fg=${white},bg=${medium_gray}] #I #W${current_flags} #[fg=${medium_gray},bg=${gray}]${left_sep}"
  else
    tmux set-window-option -g window-status-current-format "#[fg=${white},bg=${medium_gray}] #I #W${current_flags} "
  fi

  tmux set-window-option -g window-status-format "#[fg=${white}]#[bg=${gray}] #I #W${flags}"
  tmux set-window-option -g window-status-activity-style "bold"
  tmux set-window-option -g window-status-bell-style "bold"
}

# run main function
main
