// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'retrofit.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

class _RestClient implements RestClient {
  _RestClient(this._dio, {this.baseUrl}) {
    ArgumentError.checkNotNull(_dio, '_dio');
    baseUrl ??= 'https://192.168.43.23:10018/v1/';
  }

  final Dio _dio;

  String baseUrl;

  @override
  Future<Result<ResultPage<TinyMangaPage>>> getAllMangaPages(
      {page, limit}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'page': page, r'limit': limit};
    queryParameters.removeWhere((k, v) => v == null);
    final _data = <String, dynamic>{};
    final _result = await _dio.request<Map<String, dynamic>>('/manga',
        queryParameters: queryParameters,
        options: RequestOptions(
            method: 'GET',
            headers: <String, dynamic>{},
            extra: _extra,
            baseUrl: baseUrl),
        data: _data);
    final value = Result<ResultPage<TinyMangaPage>>.fromJson(_result.data);
    return value;
  }

  @override
  Future<Result<MangaPage>> getMangaPage({mid}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    queryParameters.removeWhere((k, v) => v == null);
    final _data = <String, dynamic>{};
    final _result = await _dio.request<Map<String, dynamic>>('/manga/$mid',
        queryParameters: queryParameters,
        options: RequestOptions(
            method: 'GET',
            headers: <String, dynamic>{},
            extra: _extra,
            baseUrl: baseUrl),
        data: _data);
    final value = Result<MangaPage>.fromJson(_result.data);
    return value;
  }

  @override
  Future<Result<MangaChapter>> getMangaChapter({mid, cid}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    queryParameters.removeWhere((k, v) => v == null);
    final _data = <String, dynamic>{};
    final _result = await _dio.request<Map<String, dynamic>>('/manga/$mid/$cid',
        queryParameters: queryParameters,
        options: RequestOptions(
            method: 'GET',
            headers: <String, dynamic>{},
            extra: _extra,
            baseUrl: baseUrl),
        data: _data);
    final value = Result<MangaChapter>.fromJson(_result.data);
    return value;
  }

  @override
  Future<Result<MangaPageGroupList>> getHotSerialMangas() async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.request<Map<String, dynamic>>('/list/serial',
        queryParameters: queryParameters,
        options: RequestOptions(
            method: 'GET',
            headers: <String, dynamic>{},
            extra: _extra,
            baseUrl: baseUrl),
        data: _data);
    final value = Result<MangaPageGroupList>.fromJson(_result.data);
    return value;
  }

  @override
  Future<Result<MangaPageGroupList>> getFinishedMangas() async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.request<Map<String, dynamic>>('/list/finish',
        queryParameters: queryParameters,
        options: RequestOptions(
            method: 'GET',
            headers: <String, dynamic>{},
            extra: _extra,
            baseUrl: baseUrl),
        data: _data);
    final value = Result<MangaPageGroupList>.fromJson(_result.data);
    return value;
  }

  @override
  Future<Result<MangaPageGroupList>> getLatestMangas() async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.request<Map<String, dynamic>>('/list/latest',
        queryParameters: queryParameters,
        options: RequestOptions(
            method: 'GET',
            headers: <String, dynamic>{},
            extra: _extra,
            baseUrl: baseUrl),
        data: _data);
    final value = Result<MangaPageGroupList>.fromJson(_result.data);
    return value;
  }

  @override
  Future<Result<ResultPage<TinyMangaPage>>> getRecentUpdatedMangas() async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.request<Map<String, dynamic>>('/list/updated',
        queryParameters: queryParameters,
        options: RequestOptions(
            method: 'GET',
            headers: <String, dynamic>{},
            extra: _extra,
            baseUrl: baseUrl),
        data: _data);
    final value = Result<ResultPage<TinyMangaPage>>.fromJson(_result.data);
    return value;
  }

  @override
  Future<Result<ResultPage<Category>>> getAges() async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.request<Map<String, dynamic>>('/category/age',
        queryParameters: queryParameters,
        options: RequestOptions(
            method: 'GET',
            headers: <String, dynamic>{},
            extra: _extra,
            baseUrl: baseUrl),
        data: _data);
    final value = Result<ResultPage<Category>>.fromJson(_result.data);
    return value;
  }

  @override
  Future<Result<ResultPage<Category>>> getZones() async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.request<Map<String, dynamic>>('/category/zone',
        queryParameters: queryParameters,
        options: RequestOptions(
            method: 'GET',
            headers: <String, dynamic>{},
            extra: _extra,
            baseUrl: baseUrl),
        data: _data);
    final value = Result<ResultPage<Category>>.fromJson(_result.data);
    return value;
  }

  @override
  Future<Result<ResultPage<Category>>> getGenres() async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.request<Map<String, dynamic>>('/category/genre',
        queryParameters: queryParameters,
        options: RequestOptions(
            method: 'GET',
            headers: <String, dynamic>{},
            extra: _extra,
            baseUrl: baseUrl),
        data: _data);
    final value = Result<ResultPage<Category>>.fromJson(_result.data);
    return value;
  }

  @override
  Future<Result<ResultPage<TinyMangaPage>>> getGenreMangas(
      {genre, zone, age, status, page, order}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'zone': zone,
      r'age': age,
      r'status': status,
      r'page': page,
      r'order': order
    };
    queryParameters.removeWhere((k, v) => v == null);
    final _data = <String, dynamic>{};
    final _result = await _dio.request<Map<String, dynamic>>(
        '/category/genre/$genre',
        queryParameters: queryParameters,
        options: RequestOptions(
            method: 'GET',
            headers: <String, dynamic>{},
            extra: _extra,
            baseUrl: baseUrl),
        data: _data);
    final value = Result<ResultPage<TinyMangaPage>>.fromJson(_result.data);
    return value;
  }

  @override
  Future<Result<ResultPage<SmallMangaPage>>> searchMangas(
      {keyword, page, order}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'page': page, r'order': order};
    queryParameters.removeWhere((k, v) => v == null);
    final _data = <String, dynamic>{};
    final _result = await _dio.request<Map<String, dynamic>>('/search/$keyword',
        queryParameters: queryParameters,
        options: RequestOptions(
            method: 'GET',
            headers: <String, dynamic>{},
            extra: _extra,
            baseUrl: baseUrl),
        data: _data);
    final value = Result<ResultPage<SmallMangaPage>>.fromJson(_result.data);
    return value;
  }

  @override
  Future<Result<ResultPage<SmallAuthor>>> getAllAuthors(
      {genre, zone, age, page, order}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'genre': genre,
      r'zone': zone,
      r'age': age,
      r'page': page,
      r'order': order
    };
    queryParameters.removeWhere((k, v) => v == null);
    final _data = <String, dynamic>{};
    final _result = await _dio.request<Map<String, dynamic>>('/author',
        queryParameters: queryParameters,
        options: RequestOptions(
            method: 'GET',
            headers: <String, dynamic>{},
            extra: _extra,
            baseUrl: baseUrl),
        data: _data);
    final value = Result<ResultPage<SmallAuthor>>.fromJson(_result.data);
    return value;
  }

  @override
  Future<Result<Author>> getAuthor({aid}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    queryParameters.removeWhere((k, v) => v == null);
    final _data = <String, dynamic>{};
    final _result = await _dio.request<Map<String, dynamic>>('/author/$aid',
        queryParameters: queryParameters,
        options: RequestOptions(
            method: 'GET',
            headers: <String, dynamic>{},
            extra: _extra,
            baseUrl: baseUrl),
        data: _data);
    final value = Result<Author>.fromJson(_result.data);
    return value;
  }

  @override
  Future<Result<ResultPage<SmallMangaPage>>> getAuthorMangas(
      {aid, page, order}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'page': page, r'order': order};
    queryParameters.removeWhere((k, v) => v == null);
    final _data = <String, dynamic>{};
    final _result = await _dio.request<Map<String, dynamic>>(
        '/author/$aid/manga',
        queryParameters: queryParameters,
        options: RequestOptions(
            method: 'GET',
            headers: <String, dynamic>{},
            extra: _extra,
            baseUrl: baseUrl),
        data: _data);
    final value = Result<ResultPage<SmallMangaPage>>.fromJson(_result.data);
    return value;
  }
}
