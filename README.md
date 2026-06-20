# RotationTrackerFiles.jl

**Rotation Tracker (ver.20240515)** の解析結果テキストファイルを読み込むための Julia パッケージです．

## インストール

Julia の REPL で `]` を押してパッケージモードに入り，以下を実行してください：

```julia
pkg> add https://github.com/Chihiro-g/RotationTrackerFiles.jl.git
```

### バージョン確認・アップデート

```julia
pkg> st RotationTrackerFiles   # 現在のバージョンを確認
pkg> up RotationTrackerFiles   # 最新版にアップデート
```

---

## クイックスタート

```julia
using RotationTrackerFiles

path = "path/to/result.txt"

# すべてのデータを一括取得
data = rt_data(path)

data.filename          # ファイル名（String）
data.fps               # フレームレート（Float64）
data.x                 # x座標データ（Vector{Float64}）
data.y                 # y座標データ（Vector{Float64}）
data.revolutions       # 回転数（Vector{Float64}）
data.revolutions_long  # 長軸回転数（Vector{Float64}）
```

> **ヒント：** 個別の値だけが必要な場合は，専用の関数（`rt_fps`，`rt_x` など）を使うと効率的です．

---

## オプション引数

`rt_x`，`rt_y`，`rt_data` などのデータ取得関数には，以下の共通オプション引数があります．

| 引数 | 型 | デフォルト | 説明 |
|------|----|-----------|------|
| `trim_start` | `Real` | `0.0` | データ先頭から指定秒数をスキップする（秒） |
| `trim_end` | `Real` | `0.0` | データ末尾から指定秒数を除外する（秒） |
| `cycle_time` | `Real` | `0.0` | 周期過程の場合，1周期の時間（秒）を指定するとデータを `(len_cycle × cycle_num)` の行列にreshapeして返す．端数は切り捨て |
| `pixel_size` | `Real` | `1.0` | 1ピクセルの実サイズ（座標系に掛け算される） |

### 使用例

```julia
# 最初の2秒と最後の1秒を除外し，ピクセルサイズを0.1 µm/pxとして取得
x = rt_x(path, trim_start=2.0, trim_end=1.0, pixel_size=0.1)

# 周期0.5秒のサイクル過程データを行列として取得
x_cycle = rt_x(path, cycle_time=0.5)
# → サイズ (frames_per_cycle × n_cycles) の Matrix{Float64}
```

---

## 関数リファレンス

### メタデータの取得

#### `rt_filename(path) → String`

解析ファイルに記録された元動画ファイル名を返します（1行目の `# filename`）．

```julia
rt_filename("result.txt")  # → "video.avi"
```

---

#### `rt_length(path) → Int`

データ列の全長さを返します（3行目の `# length`）．

```julia
rt_length("result.txt")  # → 3000
```

---

#### `rt_frame_range(path) → UnitRange{Int64}`

解析対象のフレーム範囲を返します（4行目の `# frame range`）．

```julia
rt_frame_range("result.txt")  # → 1:3000
```

---

#### `rt_fps(path) → Float64`

フレームレートを返します（12行目の `# frame rate`）．

```julia
rt_fps("result.txt")  # → 200.0
```

---

### データの取得（1粒子）

#### `rt_x(path; ...) → Vector{Float64} | Matrix{Float64}`

x座標（ピクセル）を返します．`pixel_size` を指定すると実座標に変換されます．

```julia
x = rt_x(path)
x = rt_x(path, pixel_size=0.1, trim_start=1.0)
```

---

#### `rt_y(path; ...) → Vector{Float64} | Matrix{Float64}`

y座標（ピクセル）を返します．オプション引数は `rt_x` と同様です．

```julia
y = rt_y(path)
```

---

#### `rt_xy(path; ...) → NamedTuple`

x座標とy座標をまとめて返します．`.x`，`.y` でアクセスします．

```julia
xy = rt_xy(path)
xy.x  # → Vector{Float64} または Matrix{Float64}
xy.y  # → Vector{Float64} または Matrix{Float64}
```

> **ヒント：** x と y を両方使う場合は，`rt_x` / `rt_y` を別々に呼ぶよりも `rt_xy` の方がファイルを1回だけ読むため高速です．

---

#### `rt_revolutions(path; ...) → Vector{Float64} | Matrix{Float64}`

回転数を返します（`pixel_size` オプションなし）．

```julia
rev = rt_revolutions(path)
rev = rt_revolutions(path, trim_start=1.0, cycle_time=0.5)
```

---

#### `rt_revolutions_long(path; ...) → Vector{Float64} | Matrix{Float64}`

長軸周りの回転数を返します（`pixel_size` オプションなし）．

```julia
rev_long = rt_revolutions_long(path)
```

---

#### `rt_data(path; ...) → NamedTuple`

すべてのデータを一括取得します．ファイルの読み込みが1回で済むため，複数のデータが必要な場合に最も効率的です．

```julia
data = rt_data(path, pixel_size=0.1, trim_start=1.0)
```

返り値のキー：

| キー | 型 | 内容 |
|------|----|------|
| `:filename` | `String` | 元動画のファイル名 |
| `:length` | `Int` | データの全長さ |
| `:frame_range` | `UnitRange{Int64}` | フレーム範囲 |
| `:fps` | `Float64` | フレームレート |
| `:x` | `Vector` / `Matrix` | x座標 |
| `:y` | `Vector` / `Matrix` | y座標 |
| `:revolutions` | `Vector` / `Matrix` | 回転数 |
| `:revolutions_long` | `Vector` / `Matrix` | 長軸回転数 |

---

### データの取得（2粒子）

#### `rt_distance(path1, path2; ...) → Vector{Float64} | Matrix{Float64}`

2つのファイルの各フレームにおけるユークリッド距離を計算して返します．

- 2ファイルの共通フレーム範囲が自動的に使用されます．
- 2ファイルの `fps` が一致している必要があります．

```julia
dist = rt_distance("particle1.txt", "particle2.txt")
dist = rt_distance("particle1.txt", "particle2.txt", pixel_size=0.1, trim_start=1.0)
```

| 引数 | 型 | 説明 |
|------|----|------|
| `path1` | `String` | 1粒子目のファイルパス |
| `path2` | `String` | 2粒子目のファイルパス |
| `trim_start` | `Real` | 先頭をスキップする秒数 |
| `trim_end` | `Real` | 末尾を除外する秒数 |
| `cycle_time` | `Real` | 1周期の時間（秒） |
| `pixel_size` | `Real` | 1ピクセルの実サイズ |