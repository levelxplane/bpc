--Copyright © 2015, Damien Dennehy
--All rights reserved.

--Redistribution and use in source and binary forms, with or without
--modification, are permitted provided that the following conditions are met:

--    * Redistributions of source code must retain the above copyright
--      notice, this list of conditions and the following disclaimer.
--    * Redistributions in binary form must reproduce the above copyright
--      notice, this list of conditions and the following disclaimer in the
--      documentation and/or other materials provided with the distribution.
--    * Neither the name of SpellCheck nor the
--      names of its contributors may be used to endorse or promote products
--      derived from this software without specific prior written permission.

--THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
--ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
--WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
--DISCLAIMED. IN NO EVENT SHALL DAMIEN DENNEHY BE LIABLE FOR ANY
--DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
--(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
--ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
--(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
--SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

_addon.name    = 'bpc'
_addon.author  = 'Berlioz@Asura'
_addon.version = '1.0.0'
_addon.command = 'bpc'

require('sets')
require('tables')
require('lists')
require('string')

files = require('files')
res = require('resources')

local PLAYER_ID = windower.ffxi.get_player().id
local PLAYER_MOB = nil
local PET_MOB = nil
local PET_ID = nil

local LAST_ACTION_TIME = os.clock()
local CONDUIT_TIME = 0
local CONDUIT_ACTIVE = false
local RAGE_COUNT = 0
local BP_COUNT = 0
local CONDUIT_COUNT = 0

local TOTAL_DAMAGE = 0

local BLOODPACT_IDS = T{
    [513] = {id=513,en="Poison Nails",ja="ポイズンネイル",element=6,icon_id=340,mp_cost=11,prefix="/pet",range=2,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [516] = {id=516,en="Meteorite",ja="プチメテオ",element=6,icon_id=340,mp_cost=108,prefix="/pet",range=4,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [518] = {id=518,en="Searing Light",ja="シアリングライト",element=6,icon_id=340,mp_cost=0,prefix="/pet",range=4,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [519] = {id=519,en="Holy Mist",ja="ホーリーミスト",element=6,icon_id=340,mp_cost=152,prefix="/pet",range=4,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [521] = {id=521,en="Regal Scratch",ja="リーガルスクラッチ",element=6,icon_id=351,mp_cost=5,prefix="/pet",range=2,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [528] = {id=528,en="Moonlit Charge",ja="ムーンリットチャージ",element=7,icon_id=341,mp_cost=17,prefix="/pet",range=2,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [529] = {id=529,en="Crescent Fang",ja="クレセントファング",element=7,icon_id=341,mp_cost=19,prefix="/pet",range=2,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [534] = {id=534,en="Eclipse Bite",ja="エクリプスバイト",element=7,icon_id=341,mp_cost=109,prefix="/pet",range=2,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [536] = {id=536,en="Howling Moon",ja="ハウリングムーン",element=7,icon_id=341,mp_cost=0,prefix="/pet",range=4,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [537] = {id=537,en="Lunar Bay",ja="ルナーベイ",element=7,icon_id=341,mp_cost=174,prefix="/pet",range=4,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [539] = {id=539,en="Impact",ja="インパクト",element=7,icon_id=341,mp_cost=222,prefix="/pet",range=9,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [544] = {id=544,en="Punch",ja="パンチ",element=0,icon_id=342,mp_cost=9,prefix="/pet",range=2,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [545] = {id=545,en="Fire II",ja="ファイアII",element=0,icon_id=342,mp_cost=24,prefix="/pet",range=8,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [546] = {id=546,en="Burning Strike",ja="バーニングストライク",element=0,icon_id=342,mp_cost=48,prefix="/pet",range=2,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [547] = {id=547,en="Double Punch",ja="ダブルパンチ",element=0,icon_id=342,mp_cost=56,prefix="/pet",range=2,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [549] = {id=549,en="Fire IV",ja="ファイアIV",element=0,icon_id=342,mp_cost=118,prefix="/pet",range=8,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [550] = {id=550,en="Flaming Crush",ja="フレイムクラッシュ",element=0,icon_id=342,mp_cost=164,prefix="/pet",range=2,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [551] = {id=551,en="Meteor Strike",ja="メテオストライク",element=0,icon_id=342,mp_cost=182,prefix="/pet",range=9,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [552] = {id=552,en="Inferno",ja="インフェルノ",element=0,icon_id=342,mp_cost=0,prefix="/pet",range=4,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [554] = {id=554,en="Conflag Strike",ja="コンフラグストライク",element=0,icon_id=342,mp_cost=141,prefix="/pet",range=9,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [560] = {id=560,en="Rock Throw",ja="ロックスロー",element=3,icon_id=343,mp_cost=10,prefix="/pet",range=9,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [561] = {id=561,en="Stone II",ja="ストーンII",element=3,icon_id=343,mp_cost=24,prefix="/pet",range=8,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [562] = {id=562,en="Rock Buster",ja="ロックバスター",element=3,icon_id=343,mp_cost=39,prefix="/pet",range=2,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [563] = {id=563,en="Megalith Throw",ja="メガリススロー",element=3,icon_id=343,mp_cost=62,prefix="/pet",range=9,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [565] = {id=565,en="Stone IV",ja="ストーンIV",element=3,icon_id=343,mp_cost=118,prefix="/pet",range=8,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [566] = {id=566,en="Mountain Buster",ja="マウンテンバスター",element=3,icon_id=343,mp_cost=164,prefix="/pet",range=2,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [567] = {id=567,en="Geocrush",ja="ジオクラッシュ",element=3,icon_id=343,mp_cost=182,prefix="/pet",range=9,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [568] = {id=568,en="Earthen Fury",ja="アースフューリー",element=3,icon_id=343,mp_cost=0,prefix="/pet",range=4,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [570] = {id=570,en="Crag Throw",ja="クラッグスロー",element=3,icon_id=343,mp_cost=124,prefix="/pet",range=9,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [576] = {id=576,en="Barracuda Dive",ja="バラクーダダイブ",element=5,icon_id=344,mp_cost=8,prefix="/pet",range=2,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [577] = {id=577,en="Water II",ja="ウォータII",element=5,icon_id=344,mp_cost=24,prefix="/pet",range=8,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [578] = {id=578,en="Tail Whip",ja="テールウィップ",element=5,icon_id=344,mp_cost=49,prefix="/pet",range=2,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [581] = {id=581,en="Water IV",ja="ウォータIV",element=5,icon_id=344,mp_cost=118,prefix="/pet",range=8,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [582] = {id=582,en="Spinning Dive",ja="スピニングダイブ",element=5,icon_id=344,mp_cost=164,prefix="/pet",range=2,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [583] = {id=583,en="Grand Fall",ja="グランドフォール",element=5,icon_id=344,mp_cost=182,prefix="/pet",range=9,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [584] = {id=584,en="Tidal Wave",ja="タイダルウェイブ",element=5,icon_id=344,mp_cost=0,prefix="/pet",range=4,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [592] = {id=592,en="Claw",ja="クロー",element=2,icon_id=345,mp_cost=7,prefix="/pet",range=2,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [593] = {id=593,en="Aero II",ja="エアロII",element=2,icon_id=345,mp_cost=24,prefix="/pet",range=8,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [597] = {id=597,en="Aero IV",ja="エアロIV",element=2,icon_id=345,mp_cost=118,prefix="/pet",range=8,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [598] = {id=598,en="Predator Claws",ja="プレデタークロー",element=2,icon_id=345,mp_cost=164,prefix="/pet",range=2,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [599] = {id=599,en="Wind Blade",ja="ウインドブレード",element=2,icon_id=345,mp_cost=182,prefix="/pet",range=9,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [600] = {id=600,en="Aerial Blast",ja="エリアルブラスト",element=2,icon_id=345,mp_cost=0,prefix="/pet",range=4,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [608] = {id=608,en="Axe Kick",ja="アクスキック",element=1,icon_id=346,mp_cost=10,prefix="/pet",range=2,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [609] = {id=609,en="Blizzard II",ja="ブリザドII",element=1,icon_id=346,mp_cost=24,prefix="/pet",range=8,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [612] = {id=612,en="Double Slap",ja="ダブルスラップ",element=1,icon_id=346,mp_cost=96,prefix="/pet",range=2,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [613] = {id=613,en="Blizzard IV",ja="ブリザドIV",element=1,icon_id=346,mp_cost=118,prefix="/pet",range=8,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [614] = {id=614,en="Rush",ja="ラッシュ",element=1,icon_id=346,mp_cost=164,prefix="/pet",range=2,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [615] = {id=615,en="Heavenly Strike",ja="ヘヴンリーストライク",element=1,icon_id=346,mp_cost=182,prefix="/pet",range=9,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [616] = {id=616,en="Diamond Dust",ja="ダイヤモンドダスト",element=1,icon_id=346,mp_cost=0,prefix="/pet",range=4,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [624] = {id=624,en="Shock Strike",ja="ショックストライク",element=4,icon_id=347,mp_cost=6,prefix="/pet",range=2,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [625] = {id=625,en="Thunder II",ja="サンダーII",element=4,icon_id=347,mp_cost=24,prefix="/pet",range=8,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [627] = {id=627,en="Thunderspark",ja="サンダースパーク",element=4,icon_id=347,mp_cost=38,prefix="/pet",range=4,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [629] = {id=629,en="Thunder IV",ja="サンダーIV",element=4,icon_id=347,mp_cost=118,prefix="/pet",range=8,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [630] = {id=630,en="Chaotic Strike",ja="カオスストライク",element=4,icon_id=347,mp_cost=164,prefix="/pet",range=2,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [631] = {id=631,en="Thunderstorm",ja="サンダーストーム",element=4,icon_id=347,mp_cost=182,prefix="/pet",range=9,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [632] = {id=632,en="Judgment Bolt",ja="ジャッジボルト",element=4,icon_id=347,mp_cost=0,prefix="/pet",range=4,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [634] = {id=634,en="Volt Strike",ja="ボルトストライク",element=4,icon_id=347,mp_cost=229,prefix="/pet",range=2,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [639] = {id=639,en="Healing Breath IV",ja="ヒールブレスIV",element=6,icon_id=359,mp_cost=0,prefix="/pet",range=9,recast_id=0,targets=5,tp_cost=0,type="BloodPactRage"},
    [640] = {id=640,en="Healing Breath",ja="ヒールブレス",element=6,icon_id=359,mp_cost=0,prefix="/pet",range=9,recast_id=0,targets=5,tp_cost=0,type="BloodPactRage"},
    [641] = {id=641,en="Healing Breath II",ja="ヒールブレスII",element=6,icon_id=359,mp_cost=0,prefix="/pet",range=9,recast_id=0,targets=5,tp_cost=0,type="BloodPactRage"},
    [642] = {id=642,en="Healing Breath III",ja="ヒールブレスIII",element=6,icon_id=359,mp_cost=0,prefix="/pet",range=9,recast_id=0,targets=5,tp_cost=0,type="BloodPactRage"},
    [643] = {id=643,en="Remove Poison",ja="キュアポイズン",element=6,icon_id=359,mp_cost=0,prefix="/pet",range=9,recast_id=0,targets=5,tp_cost=0,type="BloodPactRage"},
    [644] = {id=644,en="Remove Blindness",ja="キュアブラインド",element=6,icon_id=359,mp_cost=0,prefix="/pet",range=9,recast_id=0,targets=5,tp_cost=0,type="BloodPactRage"},
    [645] = {id=645,en="Remove Paralysis",ja="キュアパラライズ",element=6,icon_id=359,mp_cost=0,prefix="/pet",range=9,recast_id=0,targets=5,tp_cost=0,type="BloodPactRage"},
    [646] = {id=646,en="Flame Breath",ja="フレイムブレス",element=6,icon_id=353,mp_cost=0,prefix="/pet",range=7,recast_id=0,targets=32,tp_cost=0,type="BloodPactRage"},
    [647] = {id=647,en="Frost Breath",ja="フロストブレス",element=6,icon_id=354,mp_cost=0,prefix="/pet",range=7,recast_id=0,targets=32,tp_cost=0,type="BloodPactRage"},
    [648] = {id=648,en="Gust Breath",ja="ガストブレス",element=6,icon_id=355,mp_cost=0,prefix="/pet",range=7,recast_id=0,targets=32,tp_cost=0,type="BloodPactRage"},
    [649] = {id=649,en="Sand Breath",ja="サンドブレス",element=6,icon_id=356,mp_cost=0,prefix="/pet",range=7,recast_id=0,targets=32,tp_cost=0,type="BloodPactRage"},
    [650] = {id=650,en="Lightning Breath",ja="ライトニングブレス",element=6,icon_id=357,mp_cost=0,prefix="/pet",range=7,recast_id=0,targets=32,tp_cost=0,type="BloodPactRage"},
    [651] = {id=651,en="Hydro Breath",ja="ハイドロブレス",element=6,icon_id=358,mp_cost=0,prefix="/pet",range=7,recast_id=0,targets=32,tp_cost=0,type="BloodPactRage"},
    [652] = {id=652,en="Super Climb",ja="スーパークライム",element=6,icon_id=359,mp_cost=0,prefix="/pet",range=0,recast_id=0,targets=32,tp_cost=0,type="BloodPactRage"},
    [653] = {id=653,en="Remove Curse",ja="キュアカーズ",element=6,icon_id=359,mp_cost=0,prefix="/pet",range=9,recast_id=0,targets=5,tp_cost=0,type="BloodPactRage"},
    [654] = {id=654,en="Remove Disease",ja="キュアウィルス",element=6,icon_id=359,mp_cost=0,prefix="/pet",range=9,recast_id=0,targets=5,tp_cost=0,type="BloodPactRage"},
    [656] = {id=656,en="Camisado",ja="カミサドー",element=7,icon_id=348,mp_cost=20,prefix="/pet",range=8,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [662] = {id=662,en="Nether Blast",ja="ネザーブラスト",element=7,icon_id=348,mp_cost=109,prefix="/pet",range=9,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [663] = {id=663,en="Cacodemonia",ja="カコデモニア",element=7,icon_id=348,mp_cost=0,prefix="/pet",range=9,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [664] = {id=664,en="Ruinous Omen",ja="ルイナスオーメン",element=7,icon_id=348,mp_cost=0,prefix="/pet",range=4,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [665] = {id=665,en="Night Terror",ja="ナイトテラー",element=7,icon_id=348,mp_cost=177,prefix="/pet",range=4,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [667] = {id=667,en="Blindside",ja="ブラインドサイド",element=7,icon_id=348,mp_cost=147,prefix="/pet",range=8,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [668] = {id=668,en="Deconstruction",ja="ディコンストラクション",element=7,icon_id=23,mp_cost=0,prefix="/pet",range=12,recast_id=0,targets=32,tp_cost=0,type="BloodPactRage"},
    [669] = {id=669,en="Chronoshift",ja="クロノシフト",element=7,icon_id=23,mp_cost=0,prefix="/pet",range=0,recast_id=0,targets=32,tp_cost=0,type="BloodPactRage"},
    [670] = {id=670,en="Zantetsuken",ja="斬鉄剣",element=7,icon_id=349,mp_cost=0,prefix="/pet",range=8,recast_id=0,targets=32,tp_cost=0,type="BloodPactRage"},
    [671] = {id=671,en="Perfect Defense",ja="絶対防御",element=7,icon_id=350,mp_cost=0,prefix="/pet",range=0,recast_id=0,targets=32,tp_cost=0,type="BloodPactRage"},
    [780] = {id=780,en="Regal Gash",ja="リーガルガッシュ",element=6,icon_id=351,mp_cost=118,prefix="/pet",range=2,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [960] = {id=960,en="Clarsach Call",ja="クラーサクコール",element=2,icon_id=18,mp_cost=0,prefix="/pet",range=4,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [961] = {id=961,en="Welt",ja="ウェルト",element=2,icon_id=18,mp_cost=9,prefix="/pet",range=2,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [964] = {id=964,en="Roundhouse",ja="ラウンドハウス",element=2,icon_id=18,mp_cost=52,prefix="/pet",range=2,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [967] = {id=967,en="Sonic Buffet",ja="ソニックバフェット",element=2,icon_id=18,mp_cost=164,prefix="/pet",range=8,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [968] = {id=968,en="Tornado II",ja="トルネドII",element=2,icon_id=18,mp_cost=182,prefix="/pet",range=8,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
    [970] = {id=970,en="Hysteric Assault",ja="ヒステリックアサルト",element=2,icon_id=18,mp_cost=222,prefix="/pet",range=2,recast_id=173,targets=32,tp_cost=0,type="BloodPactRage"},
}

windower.register_event("action", function(act)

    if act.category == 6 or act.category == 13 then
        if windower.ffxi.get_player().main_job ~= 'SMN' then
            print('not on smn')
            windower.send_command('lua u bpc')
            return
        end
        PLAYER_MOB = windower.ffxi.get_mob_by_id(PLAYER_ID)
        if PLAYER_MOB.pet_index == nil then
            print('no pet')
            return
        end
        PET_MOB = windower.ffxi.get_mob_by_index(PLAYER_MOB.pet_index)
        PET_ID = PET_MOB.id

        local now = os.clock()

        pact = BLOODPACT_IDS[act.param]

        if CONDUIT_ACTIVE and (now - CONDUIT_TIME >= 30) then
            CONDUIT_ACTIVE = false
            print('Astral Conduit lost')
        end

        if BP_COUNT == 0 and RAGE_COUNT == 0 then
            LAST_ACTION_TIME = now
        end

        if act.param == 337 then
            time_diff = now - LAST_ACTION_TIME
            LAST_ACTION_TIME = now

            print (
                string.format('#%s: %s - delay: %s',
                    tostring(BP_COUNT),
                    'Astral Conduit',
                    string.sub(tostring(time_diff), 1, 4)
                )
            )

            CONDUIT_TIME = now
            CONDUIT_ACTIVE = true

        elseif pact ~= nil then
            -- print(act.actor_id)
            if act.actor_id == PLAYER_ID then
                -- print('player')
                time_diff = now - LAST_ACTION_TIME
                LAST_ACTION_TIME = now

                RAGE_COUNT = RAGE_COUNT + 1


                -- print (
                --     string.format('#%s: %s - delay: %s',
                --         tostring(RAGE_COUNT),
                --         'BP: Rage',
                --         tostring(time_diff):sub(1, 4)
                --     )
                -- )
            elseif act.actor_id == PET_ID then
                -- print('pet')
                time_diff = now - LAST_ACTION_TIME
                LAST_ACTION_TIME = now

                BP_COUNT = BP_COUNT + 1
                if CONDUIT_ACTIVE then
                    CONDUIT_COUNT = CONDUIT_COUNT + 1
                    pact_name = pact.en .. '(AC)'
                else
                    pact_name = pact.en
                end

                local targ = act.targets[1]
                local action = targ.actions[1]
                local dmg = action.param

                TOTAL_DAMAGE = TOTAL_DAMAGE + dmg
                local avg = TOTAL_DAMAGE / RAGE_COUNT

                print (
                    string.format('#%s: %s - delay: %s | dmg: %s | avg: %s',
                        tostring(BP_COUNT),
                        pact_name,
                        tostring(time_diff):sub(1, 4),
                        tostring(dmg),
                        tostring(avg)
                    )
                )
            end
        else
            -- print('non bp related action')
            -- pact not a BP or AC
        end
    end
end)

-- track weaponskill usage
windower.register_event('addon command',function (command, ...)
    command = command and command:lower() or 'help'
    if command == 'help' or command == 'h' or command == '?' then
        display_help()
    elseif command == 'show' then
        print('Total Rage/BPs Used:', tostring(RAGE_COUNT), tostring(BP_COUNT))
        print('BPs in AC:', tostring(CONDUIT_COUNT))
        print('Total Damage:', tostring(TOTAL_DAMAGE))

    elseif command == 'reset' then
        BP_COUNT = 0
        CONDUIT_COUNT = 0
        RAGE_COUNT = 0
        CONDUIT_ACTIVE = false

    else
        display_help()
    end
end)

--display a basic help section
function display_help()
    windower.add_to_chat(7, _addon.name .. ' v.' .. _addon.version)
    windower.add_to_chat(7, 'Usage: //ac show|reset')
end

function get_player_name(id)
    mob = windower.ffxi.get_mob_by_id(id)
    if mob and mob.in_party then
        return mob.name or '???'
    else
        return nil
    end
end
