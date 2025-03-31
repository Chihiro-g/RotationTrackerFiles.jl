module RotationTrackerFiles

#*======================================================================================================================
#* 定数
#*======================================================================================================================

#* このパッケージで対応するバージョン
const SUPPORTED_VERSION::String = "20240515"

#* インデックス
const LINE_INDEX_FILENAME::Int = 1
const LINE_INDEX_VERSION::Int = 2
const LINE_INDEX_LENGTH::Int = 3
const LINE_INDEX_FRAME_RANGE::Int = 4
const LINE_INDEX_FRAME_RATE::Int = 12
const NUM_SKIP_LINES_DATA::Int = 29

#*======================================================================================================================
#* 汎用関数
#*======================================================================================================================

#* 特定の行だけ取得する
function get_line_in_file(path::String, line_index::Int)
    open(path) do file
        for (idx, line) in enumerate(eachline(file))
            if idx == line_index
                return line
            end
        end
        throw(:line_index_out_of_range)
    end
end

#* 入力したpathがRotation Trackerのファイルかどうかを判定する
function is_rotation_tracker_file(path::String)
    # ファイルが存在するかどうか
    if !isfile(path)
        return :file_not_found
    end
    # ファイルがtextファイルかどうか
    if splitext(path)[2] != ".txt"
        return :not_text_file
    end
    # ファイルのバージョンが対応しているかどうか
    try
        line = get_line_in_file(path, LINE_INDEX_VERSION)
        version = split(line, '\t')[2]
        if version != SUPPORTED_VERSION
            return :unsupported_version
        end
        return :valid
    catch
        return :not_rotation_tracker_file
    end
end

#* スキップするフレームの数を計算する
function calc_skip_frames(skip_time::Real, fps::Float64)
    # 引数が正しいか判定
    if skip_time < 0.0 # skip_timeが負ではないか？
        show_error(:negative_skip_time, var=string(skip_time))
    end
    if fps < 0.0 # fpsが負ではないか？
        show_error(:negative_fps, var=string(fps))
    end
    # skip_timeをフレーム数に変換
    skip_frames = skip_time * fps
    # skip_framesが整数かどうか？
    if skip_frames != round(skip_frames)
        show_error(:skip_frames_is_not_integer, var=string(skip_time))
    end

    return Int(skip_frames)
end

#* スキップするフレーム数を考慮してデータの長さを計算
function calc_len_data(path::String, fps::Float64, skip_start_frames::Int, skip_end_frames::Int, cycle_time::Real)
    # データの長さを取得
    len_data_full = length(rt_frame_range(path))
    # 返すデータの長さを計算
    len_data = len_data_full - skip_start_frames - skip_end_frames
    # len_dataが負ではないか？
    if len_data <= 0.0
        show_error(:negative_len_data, var=string(len_data))
    end
    # データーの長さがサイクル一周期もない場合
    if cycle_time != 0.0 && len_data < fps * cycle_time
        show_error(:no_cycle_data, var=string(cycle_time))
    end

    return len_data
end
# データの全長さが取得済みな場合
function calc_len_data(len_data_full::Int, fps::Float64, skip_start_frames::Int, skip_end_frames::Int, cycle_time::Real)
    # 返すデータの長さを計算
    len_data = len_data_full - skip_start_frames - skip_end_frames
    # len_dataが負ではないか？
    if len_data <= 0.0
        show_error(:negative_len_data, var=string(len_data))
    end
    # データーの長さがサイクル一周期もない場合
    if cycle_time != 0.0 && len_data < fps * cycle_time
        show_error(:no_cycle_data, var=string(cycle_time))
    end

    return len_data
end

#* 共通するframe, fpsを取得
function get_common_frames_fps(path1::String, path2::String)
    # frame rangeを取得
    frame_range1 = rt_frame_range(path1)
    frame_range2 = rt_frame_range(path2)
    # 共通するframe rangeがあるか？
    if last(frame_range1) < first(frame_range2) || last(frame_range2) < first(frame_range1)
        show_error(:no_common_frame_range)
    end
    # 共通するframe rangeを計算
    frame_start = max(first(frame_range1), first(frame_range2))
    frame_end = min(last(frame_range1), last(frame_range2))
    # fpsを取得
    fps1 = rt_fps(path1)
    fps2 = rt_fps(path2)
    # fpsが一致しているか？
    if fps1 != fps2
        show_error(:fps_not_match)
    end
    fps = fps1

    return (frame_start:frame_end, frame_range1, frame_range2, fps)
end

#* error文の出力
function show_error(sym::Symbol; var::String="")
    #* 問題がない場合
    if sym == :valid
        return nothing
    end

    #* Rotation Trackerのファイルの判定
    # ファイルが存在しない
    if sym == :file_not_found
        error("The file is not found. (path = $var)")
    end
    # テキストファイルではない
    if sym == :not_text_file
        error("The file is not a text file. (path = $var)")
    end
    # Rotation Trackerのファイルではない
    if sym == :not_rotation_tracker_file
        error("The file is not a Rotation Tracker file. (path = $var)")
    end
    # 対応していないバージョン
    if sym == :unsupported_version
        error("The version of the file is not supported. (path = $var)")
    end

    #* データの取得
    # 読む行が範囲外
    if sym == :line_index_out_of_range
        error("The line index $(var) is out of range.")
    end
    # データの長さが負
    if sym == :negative_len_data
        error("The length of the data must be positive. (len_data = $var)")
    end
    # サイクル過程のデータが１周期もない
    if sym == :no_cycle_data
        error("The length of the data is less than one cycle time. (len_data = $var)")
    end

    #* スキップするフレームの数を計算
    # skip_timeが負
    if sym == :negative_skip_time
        error("The skip time must be positive. (skip_time = $var)")
    end
    # fpsが負
    if sym == :negative_fps
        error("The fps must be positive. (fps = $var)")
    end
    # skip_framesが整数でない
    if sym == :skip_frames_is_not_integer
        error("The skip frames must be integer. (skip_frames = skip_times*fps = $var)")
    end

    #* 2粒子用
    # 共通するframe rangeがない
    if sym == :no_common_frame_range
        error("The two files do not have common frame range.")
    end
    # fpsが一致しない
    if sym == :fps_not_match
        error("The fps of the two files are not matched.")
    end

    #* その他のエラー
    error("Unexpected error is occurred")
end

#*======================================================================================================================
#* 1粒子用
#*======================================================================================================================

export rt_filename
function rt_filename(path::String)
    # ファイルが適切かどうか判定
    show_error(is_rotation_tracker_file(path), var=path)
    # ファイル名を取得
    try
        line = get_line_in_file(path, LINE_INDEX_FILENAME)
        filename = split(line, '\t')[2]
        return filename
    catch error
        if typeof(error) == Symbol
            show_error(error, var=string(LINE_INDEX_FILENAME))
        else
            throw(error)
        end
    end
end

export rt_length
function rt_length(path::String)
    # ファイルが適切かどうか判定
    show_error(is_rotation_tracker_file(path), var=path)
    # データの長さを取得
    try
        line = get_line_in_file(path, LINE_INDEX_LENGTH)
        rt_len = split(line, '\t')[2] |> s -> parse(Int, s)
        return rt_len
    catch error
        if typeof(error) == Symbol
            show_error(error, var=string(LINE_INDEX_FRAME_RANGE))
        else
            throw(error)
        end
    end
end

export rt_frame_range
function rt_frame_range(path::String)
    # ファイルが適切かどうか判定
    show_error(is_rotation_tracker_file(path), var=path)
    # frame rangeを取得
    try
        line = get_line_in_file(path, LINE_INDEX_FRAME_RANGE)
        frame_start, frame_end = split(line, '\t')[2] |> s -> split(s, '-') .|> s -> parse(Int, s) + 1
        return frame_start:frame_end
    catch error
        if typeof(error) == Symbol
            show_error(error, var=string(LINE_INDEX_FRAME_RANGE))
        else
            throw(error)
        end
    end
end

export rt_fps
function rt_fps(path::String)
    # ファイルが適切かどうか判定
    show_error(is_rotation_tracker_file(path), var=path)
    # fpsを取得
    try
        line = get_line_in_file(path, LINE_INDEX_FRAME_RATE)
        fps = split(line, '\t')[2] |> s -> parse(Float64, s)
        return fps
    catch error
        if typeof(error) == Symbol
            show_error(error, var=string(LINE_INDEX_FRAME_RATE))
        else
            throw(errror)
        end
    end
end

export rt_x
function rt_x(path::String; skip_start::Real=0.0, skip_end::Real=0.0, cycle_time::Real=0.0)
    # スキップするフレーム数を計算
    fps = rt_fps(path) # ここでファイルが適切かどうかも判定
    skip_start_frames = calc_skip_frames(skip_start, fps)
    skip_end_frames = calc_skip_frames(skip_end, fps)
    # 返すデータの長さを計算
    len_data = calc_len_data(path, fps, skip_start_frames, skip_end_frames, cycle_time)
    # data_xを取得
    try
        open(path) do file
            # 読んだデータを格納する配列を確保
            data_x = Vector{Float64}(undef, len_data)
            # イテレータを作成
            iter = Iterators.drop(eachline(file), NUM_SKIP_LINES_DATA+skip_start_frames)
            iter = Iterators.take(iter, len_data)
            # 各行でタブ区切り2個目の数値を取得
            for (frame, line) in enumerate(iter)
                idx_start = findfirst('\t', line) + 1
                idx_end = findnext('\t', line, idx_start) - 1
                data_x[frame] = parse(Float64, SubString(line, idx_start, idx_end))
            end
            # サイクル過程に合わせてデータをreshape
            if cycle_time == 0.0 # サイクル過程を考慮しない
                return data_x
            else # サイクル過程を考慮する
                len_cycle = Int(fps * cycle_time)
                cycle_num, rem_frames = divrem(len_data, len_cycle)
                # reshapeして返す
                return reshape(@view(data_x[1:end-rem_frames]), len_cycle, cycle_num) |> copy
            end
        end
    catch error
        throw(error)
    end
end

export rt_y
function rt_y(path::String; skip_start::Real=0.0, skip_end::Real=0.0, cycle_time::Real=0.0)
    # スキップするフレーム数を計算
    fps = rt_fps(path) # ここでファイルが適切かどうかも判定
    skip_start_frames = calc_skip_frames(skip_start, fps)
    skip_end_frames = calc_skip_frames(skip_end, fps)
    # 返すデータの長さを計算
    len_data = calc_len_data(path, fps, skip_start_frames, skip_end_frames, cycle_time)
    # data_yを取得
    try
        open(path) do file
            # 読んだデータを格納する配列を確保
            data_y = Vector{Float64}(undef, len_data)
            # イテレータを作成
            iter = Iterators.drop(eachline(file), NUM_SKIP_LINES_DATA+skip_start_frames)
            iter = Iterators.take(iter, len_data)
            # 各行でタブ区切り2個目の数値を取得
            for (frame, line) in enumerate(iter)
                idx_start = findnext('\t', line, findfirst('\t', line)+1) + 1
                idx_end = findnext('\t', line, idx_start) - 1
                data_y[frame] = parse(Float64, SubString(line, idx_start, idx_end))
            end
            # サイクル過程に合わせてデータをreshape
            if cycle_time == 0.0 # サイクル過程を考慮しない
                return data_y
            else # サイクル過程を考慮する
                len_cycle = Int(fps * cycle_time)
                cycle_num, rem_frames = divrem(len_data, len_cycle)
                # reshapeして返す
                return reshape(@view(data_y[1:end-rem_frames]), len_cycle, cycle_num) |> copy
            end
        end
    catch error
        throw(error)
    end
end

export rt_xy
function rt_xy(path::String; skip_start::Real=0.0, skip_end::Real=0.0, cycle_time::Real=0.0)
    # スキップするフレーム数を計算
    fps = rt_fps(path) # ここでファイルが適切かどうかも判定
    skip_start_frames = calc_skip_frames(skip_start, fps)
    skip_end_frames = calc_skip_frames(skip_end, fps)
    # 返すデータの長さを計算
    len_data = calc_len_data(path, fps, skip_start_frames, skip_end_frames, cycle_time)
    # data_x, data_yを取得
    try
        open(path) do file
            # 読んだデータを格納する配列を確保
            data_x = Vector{Float64}(undef, len_data)
            data_y = Vector{Float64}(undef, len_data)
            # イテレータを作成
            iter = Iterators.drop(eachline(file), NUM_SKIP_LINES_DATA+skip_start_frames)
            iter = Iterators.take(iter, len_data)
            # 各行でタブ区切り2個目の数値と3個目の数値を取得
            for (frame, line) in enumerate(iter)
                idx_start = findfirst('\t', line) + 1
                idx_end = findnext('\t', line, idx_start) - 1
                data_x[frame] = parse(Float64, SubString(line, idx_start, idx_end))
                idx_start = idx_end + 2
                idx_end = findnext('\t', line, idx_start) - 1
                data_y[frame] = parse(Float64, SubString(line, idx_start, idx_end))
            end
            # サイクル過程に合わせてデータをreshape
            if cycle_time == 0.0 # サイクル過程を考慮しない
                return (x=data_x, y=data_y)
            else # サイクル過程を考慮する
                len_cycle = Int(fps * cycle_time)
                cycle_num, rem_frames = divrem(len_data, len_cycle)
                # reshapeして返す
                return (
                    x=reshape(@view(data_x[1:end-rem_frames]), len_cycle, cycle_num) |> copy,
                    y=reshape(@view(data_y[1:end-rem_frames]), len_cycle, cycle_num) |> copy
                )
            end
        end
    catch error
        throw(error)
    end
end

export rt_revolutions
function rt_revolutions(path::String; skip_start::Real=0.0, skip_end::Real=0.0, cycle_time::Real=0.0)
    # スキップするフレーム数を計算
    fps = rt_fps(path) # ここでファイルが適切かどうかも判定s
    skip_start_frames = calc_skip_frames(skip_start, fps)
    skip_end_frames = calc_skip_frames(skip_end, fps)
    # 返すデータの長さを計算
    len_data = calc_len_data(path, fps, skip_start_frames, skip_end_frames, cycle_time)
    # data_revolutionsを取得
    try
        open(path) do file
            # 読んだデータを格納する配列を確保
            data_revolutions = Vector{Float64}(undef, len_data)
            # イテレータを作成
            iter = Iterators.drop(eachline(file), NUM_SKIP_LINES_DATA+skip_start_frames)
            iter = Iterators.take(iter, len_data)
            # 各行でタブ区切り2個目の数値を取得
            for (frame, line) in enumerate(iter)
                idx_end = findlast('\t', line) - 1
                idx_start = findprev('\t', line, idx_end) + 1
                data_revolutions[frame] = parse(Float64, SubString(line, idx_start, idx_end))
            end
            # サイクル過程に合わせてデータをreshape
            if cycle_time == 0.0 # サイクル過程を考慮しない
                return data_revolutions
            else # サイクル過程を考慮する
                len_cycle = Int(fps * cycle_time)
                cycle_num, rem_frames = divrem(len_data, len_cycle)
                # reshapeして返す
                return reshape(@view(data_revolutions[1:end-rem_frames]), len_cycle, cycle_num) |> copy
            end
        end
    catch error
        throw(error)
    end
end

export rt_revolutions_long
function rt_revolutions_long(path::String; skip_start::Real=0.0, skip_end::Real=0.0, cycle_time::Real=0.0)
    # スキップするフレーム数を計算
    fps = rt_fps(path) # ここでファイルが適切かどうかも判定
    skip_start_frames = calc_skip_frames(skip_start, fps)
    skip_end_frames = calc_skip_frames(skip_end, fps)
    # 返すデータの長さを計算
    len_data = calc_len_data(path, fps, skip_start_frames, skip_end_frames, cycle_time)
    # data_revolutions_longを取得
    try
        open(path) do file
            # 読んだデータを格納する配列を確保
            data_revolutions_long = Vector{Float64}(undef, len_data)
            # イテレータを作成
            iter = Iterators.drop(eachline(file), NUM_SKIP_LINES_DATA+skip_start_frames)
            iter = Iterators.take(iter, len_data)
            # 各行でタブ区切り2個目の数値を取得
            for (frame, line) in enumerate(iter)
                idx_start = findlast('\t', line) + 1
                data_revolutions_long[frame] = parse(Float64, SubString(line, idx_start))
            end
            # サイクル過程に合わせてデータをreshape
            if cycle_time == 0.0 # サイクル過程を考慮しない
                return data_revolutions_long
            else # サイクル過程を考慮する
                len_cycle = Int(fps * cycle_time)
                cycle_num, rem_frames = divrem(len_data, len_cycle)
                # reshapeして返す
                return reshape(@view(data_revolutions_long[1:end-rem_frames]), len_cycle, cycle_num) |> copy
            end
        end
    catch error
        throw(error)
    end
end

export rt_data
function rt_data(path::String; skip_start::Real=0.0, skip_end::Real=0.0, cycle_time::Real=0.0)
    # ファイルが適切かどうか判定
    show_error(is_rotation_tracker_file(path), var=path)
    # データの取得
    try
        open(path) do file
            # filename,length,fpsの取得
            filename = ""
            rt_len = 0
            frame_start = 0
            frame_end = 0
            fps = 0.0
            for idx in 1:NUM_SKIP_LINES_DATA
                line = readline(file)
                if idx == LINE_INDEX_FILENAME
                    filename = split(line, '\t')[2]
                end
                if idx == LINE_INDEX_LENGTH
                    rt_len = split(line, '\t')[2] |> s -> parse(Int, s)
                end
                if idx == LINE_INDEX_FRAME_RANGE
                    frame_start, frame_end = split(line, '\t')[2] |> s -> split(s, '-') .|> s -> parse(Int, s) + 1
                end
                if idx == LINE_INDEX_FRAME_RATE
                    fps = split(line, '\t')[2] |> s -> parse(Float64, s)
                end
            end

            # dataの取得
            # スキップするフレーム数を計算
            skip_start_frames = calc_skip_frames(skip_start, fps)
            skip_end_frames = calc_skip_frames(skip_end, fps)
            # 返すデータの長さを計算
            len_data = calc_len_data(length(frame_start:frame_end), fps, skip_start_frames, skip_end_frames, cycle_time)
            # 配列を確保
            data_x = Vector{Float64}(undef, len_data)
            data_y = Vector{Float64}(undef, len_data)
            data_revolutions = Vector{Float64}(undef, len_data)
            data_revolutions_long = Vector{Float64}(undef, len_data)
            # イテレータを作成
            iter = Iterators.drop(eachline(file), skip_start_frames)
            iter = Iterators.take(iter, len_data)
            for (frame, line) in enumerate(iter)
                idx_start = findfirst('\t', line) + 1
                idx_end = findnext('\t', line, idx_start) - 1
                data_x[frame] = parse(Float64, SubString(line, idx_start, idx_end))
                idx_start = idx_end + 2
                idx_end = findnext('\t', line, idx_start) - 1
                data_y[frame] = parse(Float64, SubString(line, idx_start, idx_end))
                idx_start = idx_end + 2
                idx_end = findnext('\t', line, idx_start) - 1
                data_revolutions[frame] = parse(Float64, SubString(line, idx_start, idx_end))
                idx_start = idx_end + 2
                data_revolutions_long[frame] = parse(Float64, SubString(line, idx_start))
            end
            # サイクル過程に合わせてデータをreshape
            if cycle_time == 0.0 # サイクル過程を考慮しない
                return (
                    filename=filename,
                    length=rt_len,
                    frame_range=frame_start:frame_end,
                    fps=fps,
                    x=data_x,
                    y=data_y,
                    revolutions=data_revolutions,
                    revolutions_long=data_revolutions_long
                )
            else # サイクル過程を考慮する
                len_cycle = Int(fps * cycle_time)
                cycle_num, rem_frames = divrem(len_data, len_cycle)
                # reshapeして返す
                return (
                    filename=filename,
                    length=rt_len,
                    frame_range=frame_start:frame_end,
                    fps=fps,
                    x=reshape(@view(data_x[1:end-rem_frames]), len_cycle, cycle_num) |> copy,
                    y=reshape(@view(data_y[1:end-rem_frames]), len_cycle, cycle_num) |> copy,
                    revolutions=reshape(@view(data_revolutions[1:end-rem_frames]), len_cycle, cycle_num) |> copy,
                    revolutions_long=reshape(@view(data_revolutions_long[1:end-rem_frames]), len_cycle, cycle_num) |> copy
                )
            end
        end
    catch error
        if typeof(error) == Symbol
            show_error(error)
        else
            throw(error)
        end
    end
end

#*======================================================================================================================
#* 2粒子用
#*======================================================================================================================

export rt_distance
function rt_distance(path1::String, path2::String; skip_start::Real=0.0, skip_end::Real=0.0, cycle_time::Real=0.0)
    # ファイルが適切かどうか判定
    show_error(is_rotation_tracker_file(path1), var=path1)
    show_error(is_rotation_tracker_file(path2), var=path2)
    # ２つのファイルの共通するframe rangeとfpsを取得
    frame_range_common, frame_range_1,frame_range_2, fps = get_common_frames_fps(path1, path2)
    # スキップするフレーム数を計算
    skip_start_frames = calc_skip_frames(skip_start, fps)
    skip_end_frames = calc_skip_frames(skip_end, fps)
    # 返すデータの長さを計算
    len_data = calc_len_data(length(frame_range_common), fps, skip_start_frames, skip_end_frames, cycle_time)
    # dataの取得
    try
        open(path1) do file1
            open(path2) do file2
                # 配列の確保
                distance = Vector{Float64}(undef, len_data)
                # イテレータを作成
                iter_1 = Iterators.drop(eachline(file1), NUM_SKIP_LINES_DATA+first(frame_range_common)-first(frame_range_1)+skip_start_frames)
                iter_2 = Iterators.drop(eachline(file2), NUM_SKIP_LINES_DATA+first(frame_range_common)-first(frame_range_2)+skip_start_frames)
                iter_1 = Iterators.take(iter_1, len_data)
                iter_2 = Iterators.take(iter_2, len_data)
                iter = enumerate(zip(iter_1, iter_2))
                # dataの取得
                for (frame, lines) in iter
                    idx_start = findfirst('\t', lines[1]) + 1
                    idx_end = findnext('\t', lines[1], idx_start) - 1
                    x1 = parse(Float64, SubString(lines[1], idx_start, idx_end))
                    idx_start = idx_end + 2
                    idx_end = findnext('\t', lines[1], idx_start) - 1
                    y1 = parse(Float64, SubString(lines[1], idx_start, idx_end))
                    idx_start = findfirst('\t', lines[2]) + 1
                    idx_end = findnext('\t', lines[2], idx_start) - 1
                    x2 = parse(Float64, SubString(lines[2], idx_start, idx_end))
                    idx_start = idx_end + 2
                    idx_end = findnext('\t', lines[2], idx_start) - 1
                    y2 = parse(Float64, SubString(lines[2], idx_start, idx_end))
                    # 距離を計算
                    distance[frame] = sqrt((x1 - x2)^2 + (y1 - y2)^2)
                end
                # サイクル過程に合わせてデータをreshape
                if cycle_time == 0.0 # サイクル過程を考慮しない
                    return distance
                else # サイクル過程を考慮する
                    len_cycle = Int(fps * cycle_time)
                    cycle_num, rem_frames = divrem(len_data, len_cycle)
                    # reshapeして返す
                    return reshape(@view(distance[1:end-rem_frames]), len_cycle, cycle_num) |> copy
                end
            end
        end
    catch error
        throw(error)
    end
end

end
