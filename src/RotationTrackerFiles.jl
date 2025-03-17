module RotationTrackerFiles

#*======================================================================================================================
#* 定数
#*======================================================================================================================

#* このパッケージで対応するバージョン
const SUPPORTED_VERSION::String = "20240515"

#* インデックス
const LINE_INDEX_FILENAME::Int = 1
const LINE_INDEX_VERSION::Int = 2
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

#* error文の出力
function show_error(sym::Symbol; var::String="")
    # 問題がない場合
    if sym == :valid
        return nothing
    end
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
    # 読む行が範囲外
    if sym == :line_index_out_of_range
        error("The line index $(var) is out of range.")
    end
    # fpsが一致していない
    if sym == :fps_not_match
        error("The fps of the two files are not matched.")
    end
    # その他のエラー
    error("Unexpected error is occurred")
end

#*======================================================================================================================
#* 実装する関数
#*======================================================================================================================

export get_rt_filename
function get_rt_filename(path::String)
    # ファイルが適切かどうか判定
    show_error(is_rotation_tracker_file(path), var=path)
    # ファイル名を取得
    try
        line = get_line_in_file(path, LINE_INDEX_FILENAME)
        return split(line, '\t')[2]
    catch error
        if typeof(error) == Symbol
            show_error(error, var=string(LINE_INDEX_FILENAME))
        else
            throw(error)
        end
    end
end

export get_rt_length
function get_rt_length(path::String)
    # ファイルが適切かどうか判定
    show_error(is_rotation_tracker_file(path), var=path)
    # データの長さを取得
    try
        line = get_line_in_file(path, LINE_INDEX_FRAME_RANGE)
        frame_start, frame_end = split(line, '\t')[2] |> s -> split(s, '-') .|> s -> parse(Int, s)
        return frame_end - frame_start + 1
    catch error
        if typeof(error) == Symbol
            show_error(error, var=string(LINE_INDEX_FRAME_RANGE))
        else
            throw(error)
        end
    end
end

export get_rt_frame_range
function get_rt_frame_range(path::String)
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

export get_rt_fps
function get_rt_fps(path::String)
    # ファイルが適切かどうか判定
    show_error(is_rotation_tracker_file(path), var=path)
    # fpsを取得
    try
        line = get_line_in_file(path, LINE_INDEX_FRAME_RATE)
        return split(line, '\t')[2] |> s -> parse(Float64, s)
    catch error
        if typeof(error) == Symbol
            show_error(error, var=string(LINE_INDEX_FRAME_RATE))
        else
            throw(errror)
        end
    end
end

export get_rt_x
function get_rt_x(path::String)
    # データの長さを取得， この関数内でファイルが適切かどうかも判定
    len_data = get_rt_length(path)
    # data_xを取得
    try
        open(path) do file
            # 読んだデータを格納する配列を確保
            data_x = Vector{Float64}(undef, len_data)
            # 各行でタブ区切り2個目の数値を取得
            for (frame, line) in enumerate(Iterators.drop(eachline(file), NUM_SKIP_LINES_DATA))
                idx_start = findfirst('\t', line) + 1
                idx_end = findnext('\t', line, idx_start) - 1
                data_x[frame] = parse(Float64, SubString(line, idx_start, idx_end))
            end
            return data_x
        end
    catch error
        throw(error)
    end
end

export get_rt_y
function get_rt_y(path::String)
    # データの長さを取得， この関数内でファイルが適切かどうかも判定
    len_data = get_rt_length(path)
    # data_yを取得
    try
        open(path) do file
            # 読んだデータを格納する配列を確保
            data_y = Vector{Float64}(undef, len_data)
            # 各行でタブ区切り3個目の数値を取得
            for (frame, line) in enumerate(Iterators.drop(eachline(file), NUM_SKIP_LINES_DATA))
                idx_start = findnext('\t', line, findfirst('\t', line)+1) + 1
                idx_end = findnext('\t', line, idx_start) - 1
                data_y[frame] = parse(Float64, SubString(line, idx_start, idx_end))
            end
            return data_y
        end
    catch error
        throw(error)
    end
end

export get_rt_revolutions
function get_rt_revolutions(path::String)
    # データの長さを取得， この関数内でファイルが適切かどうかも判定
    len_data = get_rt_length(path)
    # data_revolutionsを取得
    try
        open(path) do file
            # 読んだデータを格納する配列を確保
            data_revolutions = Vector{Float64}(undef, len_data)
            # 各行でタブ区切り4個目の数値を取得
            for (frame, line) in enumerate(Iterators.drop(eachline(file), NUM_SKIP_LINES_DATA))
                idx_end = findlast('\t', line) - 1
                idx_start = findprev('\t', line, idx_end) + 1
                data_revolutions[frame] = parse(Float64, SubString(line, idx_start, idx_end))
            end
            return data_revolutions
        end
    catch error
        throw(error)
    end
end

export get_rt_revolutions_long
function get_rt_revolutions_long(path::String)
    # データの長さを取得， この関数内でファイルが適切かどうかも判定
    len_data = get_rt_length(path)
    # data_revolutions (Long-axis)を取得
    try
        open(path) do file
            # 読んだデータを格納する配列を確保
            data_revolutions_long = Vector{Float64}(undef, len_data)
            # 各行でタブ区切り5個目の数値を取得
            for (frame, line) in enumerate(Iterators.drop(eachline(file), NUM_SKIP_LINES_DATA))
                idx_start = findlast('\t', line) + 1
                data_revolutions_long[frame] = parse(Float64, SubString(line, idx_start))
            end
            return data_revolutions_long
        end
    catch error
        throw(error)
    end
end

export get_rt_data
function get_rt_data(path::String)
    # ファイルが適切かどうか判定
    show_error(is_rotation_tracker_file(path), var=path)
    # データの取得
    try
        open(path) do file
            # filename,length,fps
            filename = ""
            frame_start = 0
            frame_end = 0
            fps = 0.0
            for idx in 1:NUM_SKIP_LINES_DATA
                line = readline(file)
                if idx == LINE_INDEX_FILENAME
                    filename = split(line, '\t')[2]
                end
                if idx == LINE_INDEX_FRAME_RANGE
                    frame_start, frame_end = split(line, '\t')[2] |> s -> split(s, '-') .|> s -> parse(Int, s)
                end
                if idx == LINE_INDEX_FRAME_RATE
                    fps = split(line, '\t')[2] |> s -> parse(Float64, s)
                end
            end
            len_data = frame_end - frame_start + 1
            frame_range = (frame_start+1):(frame_end+1)
            # data
            data_x = Vector{Float64}(undef, len_data)
            data_y = Vector{Float64}(undef, len_data)
            data_revolutions = Vector{Float64}(undef, len_data)
            data_revolutions_long = Vector{Float64}(undef, len_data)
            for (frame, line) in enumerate(eachline(file))
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
            return (
                filename=filename,
                length=len_data,
                frame_range=frame_range,
                fps=fps,
                x=data_x,
                y=data_y,
                revolutions=data_revolutions,
                revolutions_long=data_revolutions_long
                )
        end
    catch error
        if typeof(error) == Symbol
            show_error(error)
        else
            throw(error)
        end
    end
end

#* 2粒子用
function get_rt_data(path1::String, path2::String)
    # ファイルが適切かどうか判定
    show_error(is_rotation_tracker_file(path1), var=path1)
    show_error(is_rotation_tracker_file(path2), var=path2)
    # データの取得
    try
        open(path1) do file1
            open(path2) do file2
                # filename,length,fps
                filename1, filename2 = "", ""
                frame_start1, frame_start2 = 0, 0
                frame_end1, frame_end2 = 0, 0
                fps = 0.0
                for (idx, lines) in enumerate(zip(eachline(file1), eachline(file2)))
                    idx == NUM_SKIP_LINES_DATA && break
                    # filename
                    if idx == LINE_INDEX_FILENAME
                        filename1 = split(lines[1], '\t')[2]
                        filename2 = split(lines[2], '\t')[2]
                    end
                    # frame_range
                    if idx == LINE_INDEX_FRAME_RANGE
                        frame_start1, frame_end1 = split(lines[1], '\t')[2] |> s -> split(s, '-') .|> s -> parse(Int, s) + 1
                        frame_start2, frame_end2 = split(lines[2], '\t')[2] |> s -> split(s, '-') .|> s -> parse(Int, s) + 1
                    end
                    # fps
                    if idx == LINE_INDEX_FRAME_RATE
                        fps1 = split(lines[1], '\t')[2] |> s -> parse(Float64, s)
                        fps2 = split(lines[2], '\t')[2] |> s -> parse(Float64, s)
                        fps1 != fps2 && show_error(:fps_not_match)
                        fps = fps1
                    end
                end
                max_frame_start = max(frame_start1, frame_start2)
                min_frame_end = min(frame_end1, frame_end2)
                len_data = min_frame_end - max_frame_start + 1
                frame_range = max_frame_start:min_frame_end
                # skip
                for _ in 1:(max_frame_start-frame_start1) readline(file1) end
                for _ in 1:(max_frame_start-frame_start2) readline(file2) end
                # data
                data_x1 = Vector{Float64}(undef, len_data)
                data_x2 = Vector{Float64}(undef, len_data)
                data_y1 = Vector{Float64}(undef, len_data)
                data_y2 = Vector{Float64}(undef, len_data)
                for frame in 1:len_data
                    line1 = readline(file1)
                    line2 = readline(file2)
                    idx_start = findfirst('\t', line1) + 1
                    idx_end = findnext('\t', line1, idx_start) - 1
                    data_x1[frame] = parse(Float64, SubString(line1, idx_start, idx_end))
                    idx_start = idx_end + 2
                    idx_end = findnext('\t', line1, idx_start) - 1
                    data_y1[frame] = parse(Float64, SubString(line1, idx_start, idx_end))
                    idx_start = findfirst('\t', line2) + 1
                    idx_end = findnext('\t', line2, idx_start) - 1
                    data_x2[frame] = parse(Float64, SubString(line2, idx_start, idx_end))
                    idx_start = idx_end + 2
                    idx_end = findnext('\t', line2, idx_start) - 1
                    data_y2[frame] = parse(Float64, SubString(line2, idx_start, idx_end))
                end
                # distance
                distance = Vector{Float64}(undef, len_data)
                @. distance = sqrt((data_x1 - data_x2)^2 + (data_y1 - data_y2)^2)
                return (
                    filename = [filename1, filename2],
                    length = len_data,
                    frame_range = frame_range,
                    fps = fps,
                    x = [data_x1, data_x2],
                    y = [data_y1, data_y2],
                    distance = distance
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
#* 実装するマクロ
#*======================================================================================================================

export @rt_filename
macro rt_filename(path)
    return :( get_rt_filename($(esc(path))) )
end

export @rt_length
macro rt_length(path)
    return :( get_rt_length($(esc(path))) )
end

export @rt_frame_range
macro rt_frame_range(path)
    return :( get_rt_frame_range($(esc(path))) )
end

export @rt_fps
macro rt_fps(path)
    return :( get_rt_fps($(esc(path))) )
end

export @rt_x
macro rt_x(path)
    return :( get_rt_x($(esc(path))) )
end

export @rt_y
macro rt_y(path)
    return :( get_rt_y($(esc(path))) )
end

export @rt_revolutions
macro rt_revolutions(path)
    return :( get_rt_revolutions($(esc(path))) )
end

export @rt_revolutions_long
macro rt_revolutions_long(path)
    return :( get_rt_revolutions_long($(esc(path))) )
end

export @rt_data
macro rt_data(paths...)
    if length(paths) == 1
        return :( get_rt_data($(esc(paths[1]))) )
    elseif length(paths) == 2
        return :( get_rt_data($(esc(paths[1])), $(esc(paths[2]))) )
    end
end

end
