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
const LINE_INDEX_FRAME_RATE::Int = 12
const NUM_SKIP_LINES_DATA::Int = 29

#* 正規表現
const NUMBER_REGEX::Regex = r"-?\d+(\.\d+)?"

#*======================================================================================================================
#* 汎用関数
#*======================================================================================================================

#* 特定の行だけ取得する
function get_line_in_file(path::String, line_index::Int)
    line = open(path) do file
        for (idx, line) in enumerate(eachline(file))
            if idx == line_index
                return line
            end
        end
        throw(:line_index_out_of_range)
    end
    return line
end

#* １行から数値だけを抜き出す
# Int
function extract_int_number_in_line(str::String)
    num = occursin(NUMBER_REGEX, str) ? match(NUMBER_REGEX, str).match : throw(:no_number_in_the_line)
    return parse(Int, num)
end

# Float64
function extract_float_number_in_line(str::String)
    num = occursin(NUMBER_REGEX, str) ? match(NUMBER_REGEX, str).match : throw(:no_number_in_the_line)
    return parse(Float64, num)
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
        error("The file does not exist.")
    end
    # テキストファイルではない
    if sym == :not_text_file
        error("The file is not a text file.")
    end
    # Rotation Trackerのファイルではない
    if sym == :not_rotation_tracker_file
        error("The file is not a Rotation Tracker file.")
    end
    # 対応していないバージョン
    if sym == :unsupported_version
        error("The version of the file is not supported. The supported version is $SUPPORTED_VERSION.")
    end
    # 読む行が範囲外
    if sym == :line_index_out_of_range
        error("The line index $(var) is out of range.")
    end
    # 行に数値が見つからない
    if sym == :no_number_in_the_line
        error("No number is found in the line. (line index = $(var))")
    end
    # その他のエラー
    error("Unexpected error is occurred")
end

#*======================================================================================================================
#* 実装する関数
#*======================================================================================================================
export get_rt_filename, get_rt_length, get_rt_fps, get_rt_x, get_rt_y, get_rt_revolutions, get_rt_revolutions_long, get_rt_data

function get_rt_filename(path::String)
    # ファイルが適切かどうか判定
    show_error(is_rotation_tracker_file(path))
    # ファイル名を取得
    try
        line = get_line_in_file(path, LINE_INDEX_FILENAME)
        return split(line, '\t')[2]
    catch error
        if typeof(error) == Symbol
            show_error(error, var=LINE_INDEX_FILENAME)
        else
            throw(error)
        end
    end
end

function get_rt_length(path::String)
    # ファイルが適切かどうか判定
    show_error(is_rotation_tracker_file(path))
    # データの長さを取得
    try
        line = get_line_in_file(path, LINE_INDEX_LENGTH)
        return extract_int_number_in_line(line)
    catch error
        if typeof(error) == Symbol
            show_error(error, var=LINE_INDEX_LENGTH)
        else
            throw(error)
        end
    end
end

function get_rt_fps(path::String)
    # ファイルが適切かどうか判定
    show_error(is_rotation_tracker_file(path))
    # fpsを取得
    try
        line = get_line_in_file(path, LINE_INDEX_FRAME_RATE)
        return extract_float_number_in_line(line)
    catch error
        if typeof(error) == Symbol
            show_error(error, var=LINE_INDEX_FRAME_RATE)
        else
            throw(errror)
        end
    end
end

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

function get_rt_data(path::String)
    # ファイルが適切かどうか判定
    show_error(is_rotation_tracker_file(path))
    # データを取得
    try
        open(path) do file
            # filename,length,fps
            filename = ""
            len_data = 0
            fps = 0.0
            for idx in 1:NUM_SKIP_LINES_DATA
                line = readline(file)
                if idx == LINE_INDEX_FILENAME
                    filename = split(line, '\t')[2]
                end
                if idx == LINE_INDEX_LENGTH
                    len_data = extract_int_number_in_line(line)
                end
                if idx == LINE_INDEX_FRAME_RATE
                    fps = extract_float_number_in_line(line)
                end
            end
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

#*======================================================================================================================
#* 実装するマクロ
#*======================================================================================================================
export @rt_filename, @rt_length, @rt_fps, @rt_x, @rt_y, @rt_revolutions, @rt_revolutions_long, @rt_data

macro rt_filename(path)
    return :( get_rt_filename($(esc(path))) )
end

macro rt_length(path)
    return :( get_rt_length($(esc(path))) )
end

macro rt_fps(path)
    return :( get_rt_fps($(esc(path))) )
end

macro rt_x(path)
    return :( get_rt_x($(esc(path))) )
end

macro rt_y(path)
    return :( get_rt_y($(esc(path))) )
end

macro rt_revolutions(path)
    return :( get_rt_revolutions($(esc(path))) )
end

macro rt_revolutions_long(path)
    return :( get_rt_revolutions_long($(esc(path))) )
end

macro rt_data(path)
    return :( get_rt_data($(esc(path))) )
end

end
