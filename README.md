# RotationTrackerFiles.jl
**RotationTrackerFiles.jl**は，Rotation Tracker (ver.20240515)の解析結果であるテキストファイルを読むためのjulia用パッケージです．

## インストール
juliaのREPL上で`]`を入力してパッケージモードに入り，以下のコマンドを実行してください．
```sh
pkg> add https://github.com/Chihiro-g/RotationTrackerFiles.jl.git
```

## アップデート
juliaのパッケージモードで以下のコマンドを実行すると，インストールされているRotationTrackerFilesのバージョンが確認できます．
```sh
pkg> st RotationTrackerFiles
```
もし最新版ではない場合，以下のコマンドでアップデートしてください．
```sh
pkg> up RotationTrackerFiles
```

## 使い方
まずはパッケージをインポートします．
```julia
using RotationTrackerFiles
```

ここでは`# frame rate`を取得する関数 `rt_fps()`を例にして説明します．
実装されている全ての関数の引数はRotation Trackerの解析結果のテキストファイルのパスです．

```julia
rt_fps(path)
```

とすることで，解析結果のテキストファイルの12行目に書かれた`# frame rate`が戻り値として`Float64`型で得られます．

## 関数一覧
* `rt_filename(path::String)::String`
  * **説明：** 1行目の`# filename`を取得する.
  * **引数：** 解析結果のテキストファイルのパス(`String`)
  * **戻り値：** 1行目の`# filename`(`String`)

* `rt_length(path::String)::Int`
  * **説明：** ３行目の`# length`を取得する．
  * **引数：** 解析結果のテキストファイルのパス(`String`)
  * **戻り値：** `# [data]`の各列の長さ(`Int`)

* `rt_frame_range(path::String)::UnitRange{Int64}`
  * **説明：** 4行目の`# frmae range`を`UnitRange{Int64}`で取得する．
  * **引数：** 解析結果のテキストファイルのパス(`String`)
  * **戻り値：** 4行目の`# frmae range`(`UnitRange{Int64}`)

* `rt_fps(path::String)::Float64`
  * **説明：** 12行目の`# frame rate`を取得する.
  * **引数：** 解析結果のテキストファイルのパス(`String`)
  * **戻り値：** 12行目の`# frame rate`(`Float64`)

* `rt_x(path::String)::Vector{Float64}`
  * **説明：** 30行目から始まる`# [data]`の`x (pixel)`を配列として取得する.
  * **引数：** 解析結果のテキストファイルのパス(`String`)
  * **オプション引数**
    * `trim_start::Real` : 単位は秒，データの初めから指定した秒数を飛ばして返す．
    * `trim_end::Real` : 単位は秒, データの終わりから指定した秒数を落として返す.
    * `cycle_time::Real` : 単位は秒, サイクル過程のデータの場合，１周期の時間を入力すると, 列優先でreshapeしてデータを返す．最後，1周期に満たないデータは捨てる.
    * `pixel_size::Real` : 1 pixelのサイズ
  * **戻り値：** `# [data]`の`x (pixel)`(`Vector{Float64}`or`Matrix{Float64}`)

* `rt_y(path::String)::Vector{Float64}`
  * **説明：** 30行目から始まる`# [data]`の`y (pixel)`を配列として取得する.
  * **引数：** 解析結果のテキストファイルのパス(`String`)
  * **オプション引数**
    * `trim_start::Real` : 単位は秒，データの初めから指定した秒数を飛ばして返す．
    * `trim_end::Real` : 単位は秒, データの終わりから指定した秒数を落として返す.
    * `cycle_time::Real` : 単位は秒, サイクル過程のデータの場合，１周期の時間を入力すると, 列優先でreshapeしてデータを返す．最後，1周期に満たないデータは捨てる.
    * `pixel_size::Real` : 1 pixelのサイズ
  * **戻り値：** `# [data]`の`y (pixel)`(`Vector{Float64}`or`Matrix{Float64}`)

* `rt_xy(path::String)::NamedTuple`
  * **説明：** 30行目から始まる`# [data]`の`x (pixel)`と`y (pixel)`をそれぞれ配列として取得する.
  * **引数：** 解析結果のテキストファイルのパス(`String`)
  * **オプション引数**
    * `trim_start::Real` : 単位は秒，データの初めから指定した秒数を飛ばして返す．
    * `trim_end::Real` : 単位は秒, データの終わりから指定した秒数を落として返す.
    * `cycle_time::Real` : 単位は秒, サイクル過程のデータの場合，１周期の時間を入力すると, 列優先でreshapeしてデータを返す．最後，1周期に満たないデータは捨てる.
    * `pixel_size::Real` : 1 pixelのサイズ
  * **戻り値：** `NamedTuple`で戻す．keysは，
    * `:x`
    * `:y`

* `rt_revolutions(path::String)::Vector{Float64}`
  * **説明：** 30行目から始まる`# [data]`の`revolutions`を配列として取得する.
  * **引数：** 解析結果のテキストファイルのパス(`String`)
  * **オプション引数**
    * `trim_start::Real` : 単位は秒，データの初めから指定した秒数を飛ばして返す．
    * `trim_end::Real` : 単位は秒, データの終わりから指定した秒数を落として返す.
    * `cycle_time::Real` : 単位は秒, サイクル過程のデータの場合，１周期の時間を入力すると, 列優先でreshapeしてデータを返す．最後，1周期に満たないデータは捨てる.
  * **戻り値：** 30行目から始まる`# [data]`の`revolutions`(`Vector{Float64}`or`Matrix{Float64}`)

* `rt_revolutions_long(path::String)::Vector{Float64}`
  * **説明：** 30行目から始まる`# [data]`の`revolutions (Long-axis)`を配列として取得する.
  * **引数：** 解析結果のテキストファイルのパス(`String`)
  * **オプション引数**
    * `trim_start::Real` : 単位は秒，データの初めから指定した秒数を飛ばして返す．
    * `trim_end::Real` : 単位は秒, データの終わりから指定した秒数を落として返す.
    * `cycle_time::Real` : 単位は秒, サイクル過程のデータの場合，１周期の時間を入力すると, 列優先でreshapeしてデータを返す．最後，1周期に満たないデータは捨てる.
  * **戻り値：** 30行目から始まる`# [data]`の`revolutions (Long-axis)`(`Vector{Float64}`or`Matrix{Float64}`)

* `rt_data(path::String)::NamedTuple`
  * **説明：** `# filename`, `# length`, `# fps`, `# [data]`を取得する．`rt_data(path).filename`のようにkeyを指定して値を得る．
  * **引数：** 解析結果のテキストファイルのパス(`String`)
  * **オプション引数**
    * `trim_start::Real` : 単位は秒，データの初めから指定した秒数を飛ばして返す．
    * `trim_end::Real` : 単位は秒, データの終わりから指定した秒数を落として返す.
    * `cycle_time::Real` : 単位は秒, サイクル過程のデータの場合，１周期の時間を入力すると, 列優先でreshapeしてデータを返す．最後，1周期に満たないデータは捨てる.
    * `pixel_size::Real` : 1 pixelのサイズ
  * **戻り値：** `NamedTuple`で戻す．keysは，
    * `:filename`
    * `:length`
    * `:frame_range`
    * `:fps`
    * `:x`
    * `:y`
    * `:revolutions`
    * `:revolutions_long`

* `rt_distance(path1::String, path2::String)::Vector{Float64}`
  * **説明：** ２つの指定したファイルから`# [data]`から`x`と`y`を取得して，各フレームでの距離(Euclid距離)を計算する.
  * **引数：** 解析結果のテキストファイルのパスを２つ(`String`)
  * **オプション引数**
    * `trim_start::Real` : 単位は秒，データの初めから指定した秒数を飛ばして返す．
    * `trim_end::Real` : 単位は秒, データの終わりから指定した秒数を落として返す.
    * `cycle_time::Real` : 単位は秒, サイクル過程のデータの場合，１周期の時間を入力すると, 列優先でreshapeしてデータを返す．最後，1周期に満たないデータは捨てる.
    * `pixel_size::Real` : 1 pixelのサイズ
  * **戻り値：** 各フレームでのEuclid距離(`Vector{Float64}`or`Matrix{Float64}`)
