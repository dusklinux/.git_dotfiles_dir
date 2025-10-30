## Audio post-processing

### Pipewire module-filter-chain

Pipewire has an internal module called [filter-chain](https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/Filter-Chain) that can create nodes to process audio input and output. See `/usr/share/pipewire/filter-chain/` for examples including equalization, virtual surround sound, LADSPA plugins and channel mixing.

#### LADSPA

You can install many LADSPA plugins from the official repositories and use them in Pipewire filter chains. To list plugin labels and available controls provided by a specific file use `analyseplugin` from the [ladspa](https://archlinux.org/packages/?name=ladspa) package:

$ analyseplugin /usr/lib/ladspa/lsp-plugins-ladspa.so

#### Systemwide parametric equalization

Copy `/usr/share/pipewire/filter-chain/sink-eq6.conf` to `/etc/pipewire/pipewire.conf.d/` (or `~/.config/pipewire/pipewire.conf.d/`).

Then edit `sink-eq6.conf` to incorporate the desired parameters. For headphones, these can be obtained from [Oratory1990's database](https://old.reddit.com/r/oratory1990/wiki/index) or, if not listed there, the [AutoEQ project](https://github.com/jaakkopasanen/AutoEq/tree/master/results/).

If you require a pre-amp, modify `eq_band_1` to apply a `bq_highshelf` filter at frequency 0Hz with a negative gain (gains from -120 to +20dB supported):

label = bq_highshelf
control = { "Freq" = 0 "Q" = 1.0 "Gain" = -7.5 }

For more than 6 bands, add more entries to the `nodes` list and corresponding `links` connecting one filter ":Out" to the next filter ":In", for instance to increase to 11 bands (preamp + 10):

                    { output = "eq_band_6:Out" input = "eq_band_7:In" }
                    { output = "eq_band_7:Out" input = "eq_band_8:In" }
                    { output = "eq_band_8:Out" input = "eq_band_9:In" }
                    { output = "eq_band_9:Out" input = "eq_band_10:In" }
                    { output = "eq_band_10:Out" input = "eq_band_11:In" }

Restart Pipewire, select "Equalizer Sink" as your default sound output device; this should then apply to all applications.