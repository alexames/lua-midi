-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local llx = require 'llx'

local _ENV, _M = llx.environment.create_module_environment()

-- Piano
acoustic_grand = 0
bright_acoustic = 1
electric_grand = 2
honky_tonk = 3
electric_piano_1 = 4
electric_piano_2 = 5
harpsichord = 6
clav = 7

-- Chrome Percussion
celesta = 8
glockenspiel = 9
music_box = 10
vibraphone = 11
marimba = 12
xylophone = 13
tubular_bells = 14
dulcimer = 15

-- Organ
drawbar_organ = 16
percussive_organ = 17
rock_organ = 18
church_organ = 19
reed_organ = 20
accoridan = 21
harmonica = 22
tango_accordian = 23

-- Guitar
acoustic_guitar_nylon = 24
acoustic_guitar_steel = 25
electric_guitar_jazz = 26
electric_guitar_clean = 27
electric_guitar_muted = 28
overdriven_guitar = 29
distortion_guitar = 30
guitar_harmonics = 31

-- Bass
acoustic_bass = 32
electric_bassfinger = 33
electric_basspick = 34
fretless_bass = 35
slap_bass_1 = 36
slap_bass_2 = 37
synth_bass_1 = 38
synth_bass_2 = 39

-- Strings
violin = 40
viola = 41
cello = 42
contrabass = 43
tremolo_strings = 44
pizzicato_strings = 45
orchestral_strings = 46
timpani = 47

-- Ensemble
string_ensemble_1 = 48
string_ensemble_2 = 49
synth_strings_1 = 50
synth_strings_2 = 51
choir_aahs = 52
voice_oohs = 53
synth_voice = 54
orchestra_hit = 55

-- Brass
trumpet = 56
trombone = 57
tuba = 58
muted_trumpet = 59
french_horn = 60
brass_section = 61
synthbrass_1 = 62
synthbrass_2 = 63

-- Reed
soprano_sax = 64
alto_sax = 65
tenor_sax = 66
baritone_sax = 67
oboe = 68
english_horn = 69
bassoon = 70
clarinet = 71

-- Pipe
piccolo = 72
flute = 73
recorder = 74
pan_flute = 75
blown_bottle = 76
skakuhachi = 77
whistle = 78
ocarina = 79

-- Synth Lead
lead_1_square = 80
lead_2_sawtooth = 81
lead_3_calliope = 82
lead_4_chiff = 83
lead_5_charang = 84
lead_6_voice = 85
lead_7_fifths = 86
lead_8_bass_lead = 87

-- Synth Pad
pad_1_new_age = 88
pad_2_warm = 89
pad_3_polysynth = 90
pad_4_choir = 91
pad_5_bowed = 92
pad_6_metallic = 93
pad_7_halo = 94
pad_8_sweep = 95

-- Synth Effects
fx_1_rain = 96
fx_2_soundtrack = 97
fx_3_crystal = 98
fx_4_atmosphere = 99
fx_5_brightness = 100
fx_6_goblins = 101
fx_7_echoes = 102
fx_8_scifi = 103

-- Ethnic
sitar = 104
banjo = 105
shamisen = 106
koto = 107
kalimba = 108
bagpipe = 109
fiddle = 110
shanai = 111

-- Percussive
tinkle_bell = 112
agogo = 113
steel_drums = 114
woodblock = 115
taiko_drum = 116
melodic_tom = 117
synth_drum = 118
reverse_cymbal = 119

-- Sound Effects
guitar_fret_noise = 120
breath_noise = 121
seashore = 122
bird_tweet = 123
telephone_ring = 124
helicopter = 125
applause = 126
gunshot = 127

return _M
