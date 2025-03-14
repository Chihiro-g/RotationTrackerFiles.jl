# RotationTrackerFiles.jl
**RotationTrackerFiles.jl**は，Rotation Tracker (ver.20240515)の解析結果であるテキストファイルを読むためのjulia用パッケージです．

## インストール
juliaのREPL上で以下のコマンドを実行してください．

```julia
julia> ]
pkg> add https://github.com/Chihiro-g/RotationTrackerFiles.jl.git
```

## 使い方
まずはパッケージをインポートします．
```julia
using RotationTrackerFiles
```

ここでは`# frame rate`を取得する関数 `get_rt_fps()`を例にして説明します．  
実装されている全ての関数・マクロの引数はRotation Trackerの解析結果のテキストファイルのパスです．

```julia
get_rt_fps(path)
```

とすることで，解析結果のテキストファイルの12行目に書かれた`# frame rate`が戻り値として`Float64`型で得られます．  
それぞれの関数には対応したマクロが実装されています．

```julia
@rt_fps path
```

とすることで，同様の結果が得られます．お好みで使い分けてください．  
実装されている関数・マクロは以下を参照してください．

## 関数・マクロ一覧
* `get_rt_filename(path::String)::String`
  * **説明：** 1行目の`# filename`を取得する.
  * **引数：** 解析結果のテキストファイルのパス(`String`)
  * **戻り値：** 1行目の`# filename`(`String`)
  * **マクロ：** `@rt_filename`

* `get_rt_length(path::String)::Int`
  * **説明：** `# [data]`の各列の長さを取得する．rotation trackerで動画の途中から解析した場合は３行目の`# length`の値と異なるので注意．
  * **引数：** 解析結果のテキストファイルのパス(`String`)
  * **戻り値：** `# [data]`の各列の長さ(`Int`)
  * **マクロ：** `@rt_length`
 
* `get_rt_frame_range(path::String)::UnitRange{Int64}`
  * **説明：** 4行目の`# frmae range`を`UnitRange{Int64}`で取得する．
  * **引数：** 解析結果のテキストファイルのパス(`String`)
  * **戻り値：** 4行目の`# frmae range`(`UnitRange{Int64}`)
  * **マクロ：** `@rt_frame_range`

* `get_rt_fps(path::String)::Float64`
  * **説明：** 12行目の`# frame rate`を取得する.
  * **引数：** 解析結果のテキストファイルのパス(`String`)
  * **戻り値：** 12行目の`# frame rate`(`Float64`)
  * **マクロ：** `@rt_fps`

* `get_rt_x(path::String)::Vector{Float64}`
  * **説明：** 30行目から始まる`# [data]`の`x (pixel)`をベクトルとして取得する.
  * **引数：** 解析結果のテキストファイルのパス(`String`)
  * **戻り値：** `# [data]`の`x (pixel)`(`Vector{Float64}`)
  * **マクロ：** `@rt_x`

* `get_rt_y(path::String)::Vector{Float64}`
  * **説明：** 30行目から始まる`# [data]`の`y (pixel)`をベクトルとして取得する.
  * **引数：** 解析結果のテキストファイルのパス(`String`)
  * **戻り値：** `# [data]`の`y (pixel)`(`Vector{Float64}`)
  * **マクロ：** `@rt_y`

* `get_rt_revolutions(path::String)::Vector{Float64}`
  * **説明：** 30行目から始まる`# [data]`の`revolutions`をベクトルとして取得する.
  * **引数：** 解析結果のテキストファイルのパス(`String`)
  * **戻り値：** 30行目から始まる`# [data]`の`revolutions`(`Vector{Float64}`)
  * **マクロ：** `@rt_revolutions`

* `get_rt_revolutions_long(path::String)::Vector{Float64}`
  * **説明：** 30行目から始まる`# [data]`の`revolutions (Long-axis)`をベクトルとして取得する.
  * **引数：** 解析結果のテキストファイルのパス(`String`)
  * **戻り値：** 30行目から始まる`# [data]`の`revolutions (Long-axis)`(`Vector{Float64}`)
  * **マクロ：** `@rt_revolutions_long`

* `get_rt_data(path::String)::NamedTuple`
  * **説明：** `# filename`, `# length`, `# fps`, `# [data]`を取得する．`get_rt_data(path).filename`のようにkeyを指定して値を得る．
  * **引数：** 解析結果のテキストファイルのパス(`String`)
  * **戻り値：**　`NamedTuple`で戻す．keysは，
    * `:filename`
    * `:length`
    * `:frame_range`
    * `:fps`
    * `:x`
    * `:y`
    * `:revolutions`
    * `:revolutions_long`
  * **マクロ：** `@rt_data`
