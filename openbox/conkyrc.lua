conky.config = {
  alignment = 'top_left',
  background = true,
  border_width = 1,
  cpu_avg_samples = 2,
  double_buffer = true,
  default_color = 'black',
  default_outline_color = 'black',
  default_shade_color = 'black',
  draw_borders = false,
  draw_graph_borders = true,
  draw_outline = false,
  draw_shades = false,
  use_xft = true,
  font = 'DejaVu Sans Mono:size=12',
  gap_x = 5,
  gap_y = 10,
  minimum_height = 5,
  minimum_width = 5,
  net_avg_samples = 2,
  no_buffers = true,
  out_to_console = false,
  out_to_stderr = false,
  extra_newline = false,
  own_window = true,
  own_window_transparent = true,
  own_window_argb_visual = true,
  own_window_class = 'Conky',
  own_window_type = 'desktop',
  stippled_borders = 0,
  update_interval = 1.0,
  uppercase = false,
  use_spacer = 'none',
  show_graph_scale = false,
  show_graph_range = false
}

conky.text = [[
KERNEL
$hr
$kernel


NETWORK
$hr
INT: ${alignr} ${execi 60 (ip addr | awk '/state UP/ {print $2}' | sed 's/.$//')}
MAC: ${alignr} ${execi 60 cat /sys/class/net/$(ip addr | awk '/state UP/ {print $2}' | sed 's/.$//')/address }
IP: ${alignr} ${execi 60 hostname -I | tr -d '[:space:]'}


SYSTEM
$hr
UPTIME: ${alignr} $uptime
CPU: ${alignr} $cpu% ${alignr 170} ${cpubar 11}
RAM: ${alignr} $memperc% ${alignr 170} ${membar 11}
SWAP: ${alignr} $swapperc% ${alignr 170} ${swapbar 11}
]]
