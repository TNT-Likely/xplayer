import 'package:test/test.dart';
import 'package:m3u_normalize/m3u_normalize.dart';

void main() {
  group('splitGroupTitle', () {
    test('分号串拆成多标签 —— 这是分组数从上百收敛到十几个的关键', () {
      expect(splitGroupTitle('Entertainment;Family;General'),
          ['Entertainment', 'Family', 'General']);
      expect(splitGroupTitle('Animation;Kids;Religious'),
          ['Animation', 'Kids', 'Religious']);
    });

    test('单个分组原样返回', () {
      expect(splitGroupTitle('News'), ['News']);
    });

    test('去掉每段前后空白', () {
      expect(splitGroupTitle(' News ; Sports '), ['News', 'Sports']);
    });

    test('空段被丢弃:首尾分号、连续分号都不产生空标签', () {
      expect(splitGroupTitle(';News;;Sports;'), ['News', 'Sports']);
      expect(splitGroupTitle(';;;'), isEmpty);
    });

    test('Undefined 一律丢弃,不分大小写 —— 它不是分组,是解析失败的残留', () {
      expect(splitGroupTitle('Undefined'), isEmpty);
      expect(splitGroupTitle('undefined'), isEmpty);
      expect(splitGroupTitle('UNDEFINED;News'), ['News']);
    });

    test('同名去重且保序,比较时不分大小写', () {
      expect(splitGroupTitle('News;news;NEWS;Sports'), ['News', 'Sports']);
    });

    test('null 与空串返回空列表,不抛异常', () {
      expect(splitGroupTitle(null), isEmpty);
      expect(splitGroupTitle(''), isEmpty);
      expect(splitGroupTitle('   '), isEmpty);
    });
  });

  group('normalizeChannel 候选选择', () {
    test('title 是人话、tvg-name 是 id 时选 title —— 现网最常见的形态', () {
      final d = normalizeChannel(
        tvgName: '1PLUS1INTERNATIONAL.UA@SD',
        title: '1+1 International',
      );
      expect(d.name, '1+1 International');
    });

    test('title 是 id、tvg-name 是人话时选 tvg-name', () {
      final d = normalizeChannel(
        tvgName: 'CCTV-1 综合',
        title: 'CCTV1.CN@HD',
      );
      expect(d.name, 'CCTV-1 综合');
    });

    test('两个都是人话时优先 title(分数相同保持出现顺序)', () {
      final d = normalizeChannel(tvgName: 'Name B', title: 'Name A');
      expect(d.name, 'Name A');
    });

    test('两个都是 id 时仍能产出清洗后的名字,不返回空', () {
      final d = normalizeChannel(
        tvgName: '2MMONDE.MA@HD',
        title: '2MMONDE.MA@HD',
      );
      expect(d.name, '2MMONDE');
      expect(d.quality, 'HD');
      expect(d.region, 'MA');
    });

    test('全部字段缺失时返回空名,不抛异常', () {
      expect(normalizeChannel().name, '');
      expect(normalizeChannel(tvgName: '', title: '  ').name, '');
    });

    test('只有 tvgId 时也能用它兜底', () {
      final d = normalizeChannel(tvgId: 'NHKWORLD.JP@HD');
      expect(d.name, 'NHKWORLD');
      expect(d.quality, 'HD');
    });
  });

  group('normalizeChannel 清晰度剥离', () {
    test('@HD / @SD / @4K 剥进 quality,不留在名字里', () {
      expect(normalizeChannel(title: 'Foo.CN@HD').quality, 'HD');
      expect(normalizeChannel(title: 'Foo.CN@SD').quality, 'SD');
      expect(normalizeChannel(title: 'Foo.CN@4K').quality, '4K');
      expect(normalizeChannel(title: 'Foo.CN@HD').name, 'Foo');
    });

    test('分辨率写法归一到四档', () {
      expect(normalizeChannel(title: 'Foo.CN@720P').quality, 'HD');
      expect(normalizeChannel(title: 'Foo.CN@1080P').quality, 'FHD');
      expect(normalizeChannel(title: 'Foo.CN@2160P').quality, '4K');
      expect(normalizeChannel(title: 'Foo.CN@480P').quality, 'SD');
    });

    test('PLUS1 不是清晰度,留在名字里而不是被当画质吞掉', () {
      final d = normalizeChannel(title: '2MMONDE.MA@PLUS1');
      expect(d.quality, isNull);
      expect(d.name, '2MMONDE PLUS1');
      expect(d.region, 'MA');
    });

    test('没有 @ 后缀时 quality 为 null', () {
      expect(normalizeChannel(title: 'CCTV-1 综合').quality, isNull);
    });
  });

  group('normalizeChannel 地区码剥离', () {
    test('结尾两位地区码剥进 region 并转大写', () {
      final d = normalizeChannel(title: '123TV.de@SD');
      expect(d.region, 'DE');
      expect(d.name, '123TV');
    });

    test('剥完会变空时不剥 —— 避免把频道名整个吃掉', () {
      final d = normalizeChannel(title: 'CN');
      expect(d.name, 'CN');
      expect(d.region, isNull);
    });

    test('三位以上的尾段不算地区码', () {
      final d = normalizeChannel(title: 'Foo.Bar');
      expect(d.region, isNull);
      expect(d.name, 'Foo Bar');
    });
  });

  group('normalizeChannel 大小写与分隔符', () {
    test('全大写且能断词时做标题式大小写', () {
      expect(normalizeChannel(title: 'DARE TO DREAM NETWORK').name,
          'Dare To Dream Network');
    });

    test('单个全大写词不动 —— 无法可靠断词,硬拆只会更糟', () {
      expect(normalizeChannel(title: 'DARETODREAMNETWORK').name,
          'DARETODREAMNETWORK');
    });

    test('已知缩写保持全大写', () {
      expect(normalizeChannel(title: 'CCTV NEWS').name, 'CCTV News');
      expect(normalizeChannel(title: 'BBC WORLD').name, 'BBC World');
      expect(normalizeChannel(title: 'NHK WORLD JAPAN').name, 'NHK World Japan');
    });

    test('含数字的词保持原样,不做首字母大写', () {
      expect(normalizeChannel(title: 'CCTV1 NEWS').name, 'CCTV1 News');
    });

    test('本身有大小写混排的名字不动', () {
      expect(normalizeChannel(title: 'Al Jazeera English').name,
          'Al Jazeera English');
    });

    test('下划线与点归一为空格并收敛连续空白', () {
      expect(normalizeChannel(title: 'Foo_Bar__Baz').name, 'Foo Bar Baz');
      expect(normalizeChannel(title: 'A  B').name, 'A B');
    });

    test('中文名不受标题式大小写影响', () {
      expect(normalizeChannel(title: '湖南卫视').name, '湖南卫视');
      expect(normalizeChannel(title: 'CCTV-1 综合').name, 'CCTV-1 综合');
    });
  });

  group('ChannelDisplay 值语义', () {
    test('同值相等,可直接用于 widget 比较与去重', () {
      const a = ChannelDisplay(name: 'X', quality: 'HD', region: 'CN');
      const b = ChannelDisplay(name: 'X', quality: 'HD', region: 'CN');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect({a, b}.length, 1);
    });

    test('任一字段不同即不等', () {
      const a = ChannelDisplay(name: 'X', quality: 'HD');
      expect(a == const ChannelDisplay(name: 'Y', quality: 'HD'), isFalse);
      expect(a == const ChannelDisplay(name: 'X', quality: 'SD'), isFalse);
    });
  });
}
