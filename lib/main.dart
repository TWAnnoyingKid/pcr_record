import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '口腔牙齒清潔狀態指數',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'NotoSansTC',
      ),
      home: const PCRRecordPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PCRRecordPage extends StatefulWidget {
  const PCRRecordPage({Key? key}) : super(key: key);

  @override
  State<PCRRecordPage> createState() => _PCRRecordPageState();
}

class _PCRRecordPageState extends State<PCRRecordPage> {
  // 定義上排牙齒號碼（從右到左）
  final List<int> upperTeethNumbers = [18, 17, 16, 15, 14, 13, 12, 11, 21, 22, 23, 24, 25, 26, 27, 28];
  // 定義下排牙齒號碼（從右到左）
  final List<int> lowerTeethNumbers = [48, 47, 46, 45, 44, 43, 42, 41, 31, 32, 33, 34, 35, 36, 37, 38];

  // 用於存儲每顆牙齒的6個部分的著色狀態
  // Map<牙齒號碼, List<是否著色>>
  final Map<int, List<bool>> teethColorStatus = {};

  // 用於標記牙齒是否缺失/不完整
  final Map<int, bool> missingTeeth = {};

  // 計算總牙齒數量和著色的牙齒面數量
  int get totalTeethCount => upperTeethNumbers.length + lowerTeethNumbers.length;
  int get totalSections => totalTeethCount * 6;

  int get coloredSectionsCount {
    int count = 0;
    teethColorStatus.forEach((toothNum, sections) {
      // 只計算非缺失牙齒的著色部分
      if (!missingTeeth[toothNum]!) {
        for (var isColored in sections) {
          if (isColored) count++;
        }
      }
    });
    return count;
  }

  // 計算有效牙齒數（非缺失的牙齒）
  int get validTeethCount {
    int count = 0;
    [...upperTeethNumbers, ...lowerTeethNumbers].forEach((toothNum) {
      if (!missingTeeth[toothNum]!) {
        count++;
      }
    });
    return count;
  }

  // 計算有效區段數
  int get validSectionsCount => validTeethCount * 6;

  double get pcrScore => validSectionsCount > 0 ? (coloredSectionsCount / validSectionsCount) * 100 : 0;

  @override
  void initState() {
    super.initState();
    // 初始化所有牙齒的著色狀態為未著色
    for (var toothNum in [...upperTeethNumbers, ...lowerTeethNumbers]) {
      teethColorStatus[toothNum] = List.generate(6, (_) => false);
      missingTeeth[toothNum] = false; // 初始化所有牙齒為非缺失
    }
  }
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('使用說明'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('1. 點擊牙齒的各個區域可標記牙菌斑附著情況'),
                SizedBox(height: 8),
                Text('2. 長按牙齒可將其標記為缺失牙齒（灰色）'),
                SizedBox(height: 8),
                Text('3. 使用雙指可放大或縮小牙齒圖，方便詳細標記'),
                SizedBox(height: 8),
                Text('4. PCR指數計算時不包含缺失牙齒'),
                SizedBox(height: 8),
                Text('5. 點擊「匯出CSV檔案」可分享紀錄'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('了解'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 獲取螢幕尺寸
    final screenSize = MediaQuery.of(context).size;

    // 根據螢幕寬度動態調整牙齒尺寸
    final isSmallScreen = screenSize.width < 360;
    final isMediumScreen = screenSize.width >= 360 && screenSize.width < 600;
    final isLargeScreen = screenSize.width >= 600;

    // 動態設定字體大小和間距
    final titleFontSize = isSmallScreen ? 12.0 : (isMediumScreen ? 14.0 : 16.0);
    final normalFontSize = isSmallScreen ? 8.0 : (isMediumScreen ? 10.0 : 12.0);
    final toothHeight = isSmallScreen ? 55.0 : (isMediumScreen ? 65.0 : 80.0);
    final horizontalPadding = isSmallScreen ? 6.0 : (isMediumScreen ? 10.0 : 16.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('口腔牙齒清潔狀態指數'),
        centerTitle: true,
        actions: [
          // 添加說明按鈕
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showHelpDialog(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                SizedBox(height: constraints.maxHeight * 0.01),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Text('提示: 長按牙齒可標記缺失', style: TextStyle(color: Colors.blue, fontSize: 12)),
                      const Spacer(),
                      // 添加提示文字
                      const Text('可用雙指縮放', style: TextStyle(color: Colors.blue, fontSize: 12)),
                    ],
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InteractiveViewer(
                        boundaryMargin: const EdgeInsets.all(20.0),
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Plaque Control Record',
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: constraints.maxHeight * 0.01),

                              // 修正：上排牙齒分為右上和左上（修正順序和文字）
                              _buildTeethRow(
                                upperTeethNumbers.sublist(0, upperTeethNumbers.length ~/ 2),
                                isUpper: true,
                                height: toothHeight,
                                position: '右上(18-11)',
                              ),

                              SizedBox(height: constraints.maxHeight * 0.01),

                              _buildTeethRow(
                                upperTeethNumbers.sublist(upperTeethNumbers.length ~/ 2),
                                isUpper: true,
                                height: toothHeight,
                                position: '左上(21-28)',
                              ),

                              SizedBox(height: constraints.maxHeight * 0.02),

                              // 修正：下排牙齒分為左下和右下（修正順序和文字）
                              _buildTeethRow(
                                lowerTeethNumbers.sublist(lowerTeethNumbers.length ~/ 2),
                                isUpper: false,
                                height: toothHeight,
                                position: '左下(31-38)',
                              ),

                              SizedBox(height: constraints.maxHeight * 0.01),

                              _buildTeethRow(
                                lowerTeethNumbers.sublist(0, lowerTeethNumbers.length ~/ 2),
                                isUpper: false,
                                height: toothHeight,
                                position: '右下(48-41)',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: constraints.maxHeight * 0.01),
                // 顯示每顆牙齒的著色情況
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // PCR 指數公式 (移到下方區塊)
                              Row(
                                children: [
                                  Text('牙菌斑指數(%) = ', style: TextStyle(fontSize: normalFontSize)),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(4.0),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text('著色區域數(紅色)區數', style: TextStyle(fontSize: normalFontSize)),
                                          const Divider(height: 5, thickness: 1),
                                          Text('總區數(牙齒數x6)', style: TextStyle(fontSize: normalFontSize)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Text(' = ', style: TextStyle(fontSize: normalFontSize)),
                                  Text(
                                    '${pcrScore.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: normalFontSize,
                                    ),
                                  ),
                                ],
                              ),

                              const Divider(height: 16),

                              // 重新組織牙齒記錄詳情
                              // 上排(右上+左上)
                              Text(
                                '上排牙齒:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: normalFontSize + 2,
                                ),
                              ),
                              Row(
                                children: [
                                  // 右上
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('右上:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: normalFontSize,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        ...getToothDetailsList(
                                            teethNumbers: upperTeethNumbers.sublist(0, upperTeethNumbers.length ~/ 2),
                                            fontSize: normalFontSize,
                                            sorted: true,
                                            descending: true
                                        ),
                                      ],
                                    ),
                                  ),
                                  // 左上
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('左上:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: normalFontSize,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        ...getToothDetailsList(
                                            teethNumbers: upperTeethNumbers.sublist(upperTeethNumbers.length ~/ 2),
                                            fontSize: normalFontSize,
                                            sorted: true,
                                            descending: false
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const Divider(height: 16),

                              // 下排(左下+右下)
                              Text(
                                '下排牙齒:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: normalFontSize + 2,
                                ),
                              ),
                              Row(
                                children: [
                                  // 左下
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('左下:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: normalFontSize,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        ...getToothDetailsList(
                                            teethNumbers: lowerTeethNumbers.sublist(lowerTeethNumbers.length ~/ 2),
                                            fontSize: normalFontSize,
                                            sorted: true,
                                            descending: false
                                        ),
                                      ],
                                    ),
                                  ),
                                  // 右下
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('右下:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: normalFontSize,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        ...getToothDetailsList(
                                            teethNumbers: lowerTeethNumbers.sublist(0, lowerTeethNumbers.length ~/ 2),
                                            fontSize: normalFontSize,
                                            sorted: true,
                                            descending: true
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: _clearAll,
                child: const Text('清除全部'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _saveRecord();
                },
                child: const Text('匯出CSV檔案'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 建立牙齒列
  Widget _buildTeethRow(List<int> teethNumbers, {required bool isUpper, required double height, required String position}) {
    // 確保牙齒號碼是按正確順序顯示的
    final sortedTeethNumbers = List<int>.from(teethNumbers);
    if (position == '右上(18-11)' || position == '右下(48-41)') {
      // 右側區域應該是降序排列
      sortedTeethNumbers.sort((a, b) => b.compareTo(a));
    } else {
      // 左側區域應該是升序排列
      sortedTeethNumbers.sort();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 添加分區標題 (左上/右上/左下/右下)
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
          child: Text(
            position,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: sortedTeethNumbers.map((toothNum) {
              return _buildTooth(toothNum, isUpper: isUpper, height: height);
            }).toList(),
          ),
        ),
      ],
    );
  }

  // 建立單顆牙齒
  Widget _buildTooth(int toothNum, {required bool isUpper, required double height}) {
    // 取得此牙齒的著色狀態
    final sections = teethColorStatus[toothNum]!;
    // 取得此牙齒是否缺失
    final isMissing = missingTeeth[toothNum]!;

    // 根據牙齒高度動態計算字體大小
    final fontSize = (height / 10).clamp(7.0, 10.0);

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 牙齒編號
          Text(
            '$toothNum',
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
          ),
          // 牙齒繪製 - 使用 GestureDetector 以支持長按功能
          GestureDetector(
            onLongPress: () {
              // 切換牙齒的缺失狀態
              setState(() {
                missingTeeth[toothNum] = !isMissing;
                // 如果標記為缺失，清除該牙齒的所有著色
                if (missingTeeth[toothNum]!) {
                  teethColorStatus[toothNum] = List.generate(6, (_) => false);
                }
              });
            },
            child: Container(
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: ClipRRect(
                // 將整個區域裁剪為橢圓形
                borderRadius: BorderRadius.circular(height / 2),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1.0),
                    borderRadius: BorderRadius.circular(height / 2),
                    // 如果牙齒缺失，顯示為灰色
                    color: isMissing ? Colors.grey.shade300 : null,
                  ),
                  child: isMissing
                      ? Center(
                    child: Icon(
                      Icons.do_not_disturb,
                      color: Colors.grey.shade700,
                      size: height / 2,
                    ),
                  )
                      : Column(
                    children: [
                      // 牙齒上半部（3個區域）
                      Expanded(
                        child: Row(
                          children: [
                            _buildToothSection(toothNum, 0, sections[0]),
                            _buildToothSection(toothNum, 1, sections[1]),
                            _buildToothSection(toothNum, 2, sections[2]),
                          ],
                        ),
                      ),
                      // 添加一條水平分隔線
                      Container(
                        height: 1,
                        color: Colors.black,
                      ),
                      // 牙齒下半部（3個區域）
                      Expanded(
                        child: Row(
                          children: [
                            _buildToothSection(toothNum, 3, sections[3]),
                            _buildToothSection(toothNum, 4, sections[4]),
                            _buildToothSection(toothNum, 5, sections[5]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 建立牙齒的單一區塊
  Widget _buildToothSection(int toothNum, int sectionIndex, bool isColored) {
    // 檢查牙齒是否標記為缺失
    if (missingTeeth[toothNum]!) {
      return Expanded(child: Container()); // 如果牙齒缺失，返回空容器
    }

    // 根據區塊位置設定邊框
    Border? border;
    if (sectionIndex == 0) { // 左上
      border = Border(right: BorderSide(color: Colors.black, width: 0.5));
    } else if (sectionIndex == 1) { // 中上
      border = Border(
        left: BorderSide(color: Colors.black, width: 0.5),
        right: BorderSide(color: Colors.black, width: 0.5),
      );
    } else if (sectionIndex == 2) { // 右上
      border = Border(left: BorderSide(color: Colors.black, width: 0.5));
    } else if (sectionIndex == 3) { // 左下
      border = Border(right: BorderSide(color: Colors.black, width: 0.5));
    } else if (sectionIndex == 4) { // 中下
      border = Border(
        left: BorderSide(color: Colors.black, width: 0.5),
        right: BorderSide(color: Colors.black, width: 0.5),
      );
    } else if (sectionIndex == 5) { // 右下
      border = Border(left: BorderSide(color: Colors.black, width: 0.5));
    }

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            teethColorStatus[toothNum]![sectionIndex] = !isColored;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isColored ? Colors.red : Colors.transparent,
            border: border,
          ),
        ),
      ),
    );
  }

  // 獲取牙齒詳細列表
  List<Widget> getToothDetailsList({
    double fontSize = 12.0,
    List<int>? teethNumbers,  // 可選參數：指定要顯示的牙齒號碼
    bool sorted = false,      // 是否對牙齒號碼進行排序
    bool descending = false   // 排序方向
  }) {
    List<Widget> details = [];

    // 如果未指定牙齒號碼，則使用所有牙齒
    final teeth = teethNumbers ?? [...upperTeethNumbers, ...lowerTeethNumbers];

    // 如果需要排序
    if (sorted) {
      // 複製列表以避免影響原始資料
      final sortedTeeth = List<int>.from(teeth);
      if (descending) {
        sortedTeeth.sort((a, b) => b.compareTo(a)); // 降序
      } else {
        sortedTeeth.sort(); // 升序
      }

      // 使用排序後的列表
      for (var toothNum in sortedTeeth) {
        final sections = teethColorStatus[toothNum]!;
        final coloredCount = sections.where((isColored) => isColored).length;
        final isMissing = missingTeeth[toothNum]!;

        details.add(Padding(
          padding: const EdgeInsets.only(left: 8.0, top: 2.0),
          child: Row(
            children: [
              Text(
                '$toothNum: ',
                style: TextStyle(fontSize: fontSize),
              ),
              isMissing
                  ? Text('缺失', style: TextStyle(fontSize: fontSize, color: Colors.grey))
                  : Text('著色 $coloredCount/6', style: TextStyle(fontSize: fontSize)),
            ],
          ),
        ));
      }

      return details;
    }

    // 以下是原始的處理方式 (當sorted=false時)
    // 處理上排牙齒
    details.add(Text('上排牙齒：', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)));
    for (var toothNum in upperTeethNumbers) {
      final sections = teethColorStatus[toothNum]!;
      final coloredCount = sections.where((isColored) => isColored).length;
      final isMissing = missingTeeth[toothNum]!;

      details.add(Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 4.0),
        child: Row(
          children: [
            Text(
              '牙齒 $toothNum: ',
              style: TextStyle(fontSize: fontSize),
            ),
            isMissing
                ? Text('缺失', style: TextStyle(fontSize: fontSize, color: Colors.grey))
                : Text('著色 $coloredCount/6', style: TextStyle(fontSize: fontSize)),
          ],
        ),
      ));
    }

    details.add(SizedBox(height: fontSize));

    // 處理下排牙齒
    details.add(Text('下排牙齒：', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)));
    for (var toothNum in lowerTeethNumbers) {
      final sections = teethColorStatus[toothNum]!;
      final coloredCount = sections.where((isColored) => isColored).length;
      final isMissing = missingTeeth[toothNum]!;

      details.add(Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 4.0),
        child: Row(
          children: [
            Text(
              '牙齒 $toothNum: ',
              style: TextStyle(fontSize: fontSize),
            ),
            isMissing
                ? Text('缺失', style: TextStyle(fontSize: fontSize, color: Colors.grey))
                : Text('著色 $coloredCount/6', style: TextStyle(fontSize: fontSize)),
          ],
        ),
      ));
    }

    return details;
  }

  // 清除所有著色
  void _clearAll() {
    setState(() {
      for (var toothNum in teethColorStatus.keys) {
        teethColorStatus[toothNum] = List.generate(6, (_) => false);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已清除所有著色')),
    );
  }

  // 儲存紀錄為CSV檔案
  Future<void> _saveRecord() async {
    try {
      // 檢查權限
      if (Platform.isAndroid || Platform.isIOS) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('需要儲存權限才能匯出CSV檔案')),
            );
            return;
          }
        }
      }

      // 獲取應用程式文件目錄
      final directory = await getApplicationDocumentsDirectory();

      // 建立CSV檔案名稱，格式為PCR_Record_日期時間.csv
      final now = DateTime.now();
      final formatter = DateFormat('yyyyMMdd_HHmmss');
      final fileName = 'PCR_Record_${formatter.format(now)}.csv';
      final file = File('${directory.path}/$fileName');

      // 建立CSV內容
      final List<String> csvRows = [];

      // 添加標題行
      csvRows.add('牙齒號碼,牙齒狀態,牙菌斑附著情況');

      // 添加上排牙齒資料
      for (var toothNum in upperTeethNumbers) {
        final sections = teethColorStatus[toothNum]!;
        final coloredCount = sections.where((isColored) => isColored).length;
        final isMissing = missingTeeth[toothNum]!;

        // 如果牙齒缺失，記錄為缺失；否則記錄著色比例
        if (isMissing) {
          csvRows.add('牙齒$toothNum,缺失,0.00');
        } else {
          // 著色數量以小數點格式儲存
          csvRows.add('牙齒$toothNum,正常,${(coloredCount / 6).toStringAsFixed(2)}');
        }
      }

      // 添加下排牙齒資料
      for (var toothNum in lowerTeethNumbers) {
        final sections = teethColorStatus[toothNum]!;
        final coloredCount = sections.where((isColored) => isColored).length;
        final isMissing = missingTeeth[toothNum]!;

        // 如果牙齒缺失，記錄為缺失；否則記錄著色比例
        if (isMissing) {
          csvRows.add('牙齒$toothNum,缺失,0.00');
        } else {
          // 著色數量以小數點格式儲存
          csvRows.add('牙齒$toothNum,正常,${(coloredCount / 6).toStringAsFixed(2)}');
        }
      }

      // 添加PCR總指數
      csvRows.add('PCR指數(%),${pcrScore.toStringAsFixed(2)}');

      // 將CSV內容寫入檔案
      await file.writeAsString(csvRows.join('\n'));

      // 分享CSV檔案 (適用於Flutter 3.7)
      await Share.shareFiles([file.path],
          text: '牙菌斑控制紀錄(PCR)',
          subject: '牙菌斑控制紀錄 ${formatter.format(now)}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('紀錄已匯出為CSV檔案: $fileName')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('匯出CSV檔案失敗: $e')),
      );
    }
  }
}