import 'package:flutter/material.dart';
import '../../constants/mate_theme.dart';

/// =============================================================
// GameDetailScreen - Khung chung cho mọi trò chơi.
//
// Bố cục:
//   - Header: nút Back + tên game + icon
//   - Khu vực nội dung game (do game tự cung cấp qua [child])
//
// Tất cả 4 game dưới đây đều là UI demo với mock data rõ ràng,
// sẵn sàng tích hợp business logic sau (CP2/CP3).
// =============================================================

class GameDetailScreen extends StatelessWidget {
  final String title;
  final String emoji;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const GameDetailScreen({
    super.key,
    required this.title,
    required this.emoji,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEBF1),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFC1D3), Color(0xFFFFEBF1)],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: MateColors.plum),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.7),
                      shape: const CircleBorder(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: MateShadows.avatar,
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$emoji  $title',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: MateColors.plum,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Body game
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// 1. Hiểu nhau bao nhiêu? - Trắc nghiệm (QuizGame)
// =====================================================================
class QuizGame extends StatefulWidget {
  const QuizGame({super.key});
  @override
  State<QuizGame> createState() => _QuizGameState();
}

class _QuizGameState extends State<QuizGame> {
  static const _questions = [
    _QuizQ(
      'Khi người yêu buồn, điều gì giúp họ vui lên nhất?',
      ['Một cái ôm thật chặt', 'Mua đồ ăn vặt', 'Cho không gian', 'Nhắn tin hỏi han'],
    ),
    _QuizQ(
      'Buổi hẹn hò lý tưởng của hai bạn là gì?',
      ['Xem phim cùng nhau', 'Nấu ăn tại nhà', 'Đi dạo công viên', 'Du lịch ngắn ngày'],
    ),
    _QuizQ(
      'Món ăn nào người yêu thích nhất?',
      ['Phở bò', 'Bún bò Huế', 'Cơm tấm', 'Bánh mì'],
    ),
    _QuizQ(
      'Nếu chỉ có 24h bên nhau, bạn sẽ làm gì?',
      ['Nấu ăn cùng nhau', 'Đi chơi xa', 'Ở nhà xem phim', 'Đi mua sắm'],
    ),
    _QuizQ(
      'Điều bạn yêu thích nhất ở người yêu?',
      ['Nụ cười', 'Sự kiên nhẫn', 'Trí thông minh', 'Sự hài hước'],
    ),
  ];

  int _idx = 0;
  int _correct = 0;
  int? _picked;
  String _phase = 'idle';

  void _start() {
    setState(() {
      _idx = 0;
      _correct = 0;
      _picked = null;
      _phase = 'playing';
    });
  }

  void _pick(int i) {
    if (_picked != null) return;
    final isCorrect = i == 0; // Mock: đáp án đầu là đúng.
    setState(() {
      _picked = i;
      if (isCorrect) _correct++;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      if (_idx < _questions.length - 1) {
        setState(() {
          _idx++;
          _picked = null;
        });
      } else {
        setState(() => _phase = 'done');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == 'idle') {
      return GameIntro(
        icon: Icons.favorite_rounded,
        iconColor: const Color(0xFFE11D48),
        title: 'Hiểu nhau bao nhiêu?',
        description:
            'Mỗi câu hỏi, hãy chọn đáp án bạn nghĩ là phù hợp với cả hai. '
            'Sau khi hoàn thành, hai bạn sẽ biết mức độ "đồng điệu" của mình.',
        ctaLabel: 'Bắt đầu chơi',
        onCta: _start,
      );
    }
    if (_phase == 'done') {
      return GameResult(
        icon: Icons.emoji_events_rounded,
        title: 'Hoàn thành rồi!',
        scoreText: '$_correct / ${_questions.length} câu trùng khớp',
        subtitle: 'Cùng chia sẻ kết quả với người yêu nhé 💕',
        onPlayAgain: _start,
      );
    }
    final q = _questions[_idx];
    final progress = (_idx + 1) / _questions.length;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(MateRadius.card),
            border: Border.all(color: MateColors.border),
            boxShadow: MateShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Câu ${_idx + 1}/${_questions.length}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: MateColors.plum.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    'Đúng: $_correct',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: MateColors.pink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFFFE0EA),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(MateColors.pink),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFB1CB), Color(0xFFFFD8E4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(MateRadius.card),
            boxShadow: MateShadows.hero,
          ),
          child: Text(
            q.text,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 18),
        ...List.generate(q.options.length, (i) {
          final picked = _picked == i;
          final isCorrectAnswer = i == 0;
          Color bg = Colors.white;
          Color border = MateColors.border;
          Color textColor = MateColors.plum;
          IconData? trailing;
          if (_picked != null) {
            if (isCorrectAnswer) {
              bg = const Color(0xFFDCFCE7);
              border = const Color(0xFF22C55E);
              trailing = Icons.check_circle_rounded;
            } else if (picked) {
              bg = const Color(0xFFFEE2E2);
              border = const Color(0xFFEF4444);
              trailing = Icons.cancel_rounded;
            }
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: bg,
              borderRadius: BorderRadius.circular(MateRadius.card),
              child: InkWell(
                borderRadius: BorderRadius.circular(MateRadius.card),
                onTap: _picked == null ? () => _pick(i) : null,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(MateRadius.card),
                    border: Border.all(color: border, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: MateColors.subtlePink,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          String.fromCharCode(65 + i),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: MateColors.pink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          q.options[i],
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                      if (trailing != null)
                        Icon(trailing, color: border, size: 22),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _QuizQ {
  final String text;
  final List<String> options;
  const _QuizQ(this.text, this.options);
}

// =====================================================================
// 2. Caro tình yêu - Tic Tac Toe 3x3 (TicTacToeGame)
// =====================================================================
class TicTacToeGame extends StatefulWidget {
  const TicTacToeGame({super.key});
  @override
  State<TicTacToeGame> createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame> {
  static const _winLines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8],
    [0, 3, 6], [1, 4, 7], [2, 5, 8],
    [0, 4, 8], [2, 4, 6],
  ];
  List<String?> _board = List.filled(9, null);
  bool _xTurn = true;
  List<int>? _winLine;
  bool _started = false;

  void _start() {
    setState(() {
      _board = List.filled(9, null);
      _xTurn = true;
      _winLine = null;
      _started = true;
    });
  }

  void _play(int i) {
    if (_board[i] != null || _winLine != null) return;
    setState(() {
      _board[i] = _xTurn ? 'X' : 'O';
      _xTurn = !_xTurn;
      _checkWin();
    });
  }

  void _checkWin() {
    for (final line in _winLines) {
      final a = _board[line[0]];
      if (a != null && a == _board[line[1]] && a == _board[line[2]]) {
        _winLine = line;
        return;
      }
    }
  }

  bool get _isDraw => _winLine == null && !_board.contains(null);

  String get _status {
    if (_winLine != null) return '${_board[_winLine![0]]} thắng!';
    if (_isDraw) return 'Hòa rồi 💞';
    return 'Lượt của ${_xTurn ? "X" : "O"}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) {
      return GameIntro(
        icon: Icons.grid_3x3_rounded,
        iconColor: const Color(0xFF9333EA),
        title: 'Caro tình yêu',
        description:
            'X đi trước, sau đó đến O. Ai có 3 ô liên tiếp (ngang, dọc, chéo) trước là thắng. '
            'Cùng người yêu thử tài chiến thuật nào!',
        ctaLabel: 'Bắt đầu chơi',
        onCta: _start,
      );
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(MateRadius.card),
            border: Border.all(color: MateColors.border),
            boxShadow: MateShadows.soft,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _status,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: MateColors.plum,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(MateRadius.card),
            border: Border.all(color: MateColors.border),
            boxShadow: MateShadows.soft,
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 9,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (_, i) {
              final v = _board[i];
              final winCell = _winLine?.contains(i) ?? false;
              final isX = v == 'X';
              return Material(
                color: winCell
                    ? const Color(0xFFFCE7F3)
                    : const Color(0xFFFFF7FA),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _play(i),
                  child: Center(
                    child: v == null
                        ? const SizedBox.shrink()
                        : Text(
                            v,
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: isX
                                  ? MateColors.pinkDeep
                                  : const Color(0xFF9333EA),
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legend('X', MateColors.pinkDeep, 'Người yêu'),
            const SizedBox(width: 16),
            _legend('O', const Color(0xFF9333EA), 'Bạn'),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _start,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Chơi lại'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: MateColors.pink,
                  side: const BorderSide(color: MateColors.pink, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MateRadius.pill),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Kết thúc'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MateColors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MateRadius.pill),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _legend(String sym, Color c, String who) => Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              sym,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: c,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            who,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: MateColors.plum.withOpacity(0.7),
            ),
          ),
        ],
      );
}

// =====================================================================
// 3. Đoán ý người yêu (MindReadGame)
// =====================================================================
class MindReadGame extends StatefulWidget {
  const MindReadGame({super.key});
  @override
  State<MindReadGame> createState() => _MindReadGameState();
}

class _MindReadGameState extends State<MindReadGame> {
  static const _questions = [
    _QuizQ(
      'Nếu hôm nay là sinh nhật của người yêu, bạn sẽ tặng gì?',
      ['Một bó hoa', 'Một món quà handmade', 'Một bữa tối lãng mạn', 'Một chuyến đi chơi'],
    ),
    _QuizQ(
      'Người yêu thích nhất được nghe câu nào từ bạn?',
      ['"Anh/em yêu em/anh"', '"Cảm ơn em/anh"', '"Em/anh tự hào về anh/em"', '"Anh/em nhớ em/anh"'],
    ),
    _QuizQ(
      'Màu sắc nào người yêu thích nhất?',
      ['Hồng pastel', 'Trắng', 'Đen', 'Xanh dương'],
    ),
  ];

  int _idx = 0;
  int? _pickA;
  int? _pickB;
  int _matches = 0;
  String _phase = 'idle';

  void _start() {
    setState(() {
      _idx = 0;
      _pickA = null;
      _pickB = null;
      _matches = 0;
      _phase = 'playerA';
    });
  }

  void _next() {
    if (_phase == 'playerA') {
      setState(() => _phase = 'playerB');
    } else if (_phase == 'playerB') {
      if (_pickA == _pickB) _matches++;
      setState(() => _phase = 'reveal');
    } else if (_phase == 'reveal') {
      if (_idx < _questions.length - 1) {
        setState(() {
          _idx++;
          _pickA = null;
          _pickB = null;
          _phase = 'playerA';
        });
      } else {
        setState(() => _phase = 'done');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == 'idle') {
      return GameIntro(
        icon: Icons.psychology_rounded,
        iconColor: const Color(0xFF0284C7),
        title: 'Đoán ý người yêu',
        description:
            'Lần lượt mỗi người chọn đáp án cho cùng một câu hỏi. Nếu cả hai chọn giống nhau — '
            'bạn đang thật sự "đồng điệu"!',
        ctaLabel: 'Bắt đầu chơi',
        onCta: _start,
      );
    }
    if (_phase == 'done') {
      return GameResult(
        icon: Icons.favorite_rounded,
        title: 'Xong rồi!',
        scoreText: '$_matches / ${_questions.length} câu trùng ý',
        subtitle: 'Cùng chia sẻ những câu trả lời khác nhau để hiểu nhau hơn nha.',
        onPlayAgain: _start,
      );
    }

    final q = _questions[_idx];
    final isA = _phase == 'playerA';
    final isReveal = _phase == 'reveal';
    final match = _pickA == _pickB;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(MateRadius.card),
            border: Border.all(color: MateColors.border),
            boxShadow: MateShadows.soft,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isA
                    ? MateColors.pink
                    : const Color(0xFF9333EA),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isA
                      ? 'Lượt của BẠN — chọn đáp án'
                      : 'Lượt của NGƯỜI YÊU — chọn đáp án',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: MateColors.plum,
                  ),
                ),
              ),
              Text(
                'Câu ${_idx + 1}/${_questions.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: MateColors.plum.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFBAE6FD), Color(0xFFE0F2FE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(MateRadius.card),
            boxShadow: MateShadows.soft,
          ),
          child: Text(
            isReveal ? 'Kết quả' : q.text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0C4A6E),
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (isReveal) _revealPanel(q, match) else _optionsPanel(q, isA),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (isA && _pickA == null) return;
              if (!isA && _pickB == null) return;
              _next();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MateColors.pink,
              foregroundColor: Colors.white,
              disabledBackgroundColor: MateColors.subtlePink,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MateRadius.pill),
              ),
            ),
            child: Text(
              isA
                  ? (_pickA == null ? 'Chọn đáp án trước' : 'Xong — chuyển lượt B')
                  : (_pickB == null ? 'Chọn đáp án trước' : 'So sánh'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _optionsPanel(_QuizQ q, bool isA) {
    final current = isA ? _pickA : _pickB;
    return Column(
      children: List.generate(q.options.length, (i) {
        final picked = current == i;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: picked ? const Color(0xFFFCE7F3) : Colors.white,
            borderRadius: BorderRadius.circular(MateRadius.card),
            child: InkWell(
              borderRadius: BorderRadius.circular(MateRadius.card),
              onTap: () {
                setState(() {
                  if (isA) {
                    _pickA = i;
                  } else {
                    _pickB = i;
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(MateRadius.card),
                  border: Border.all(
                    color: picked ? MateColors.pink : MateColors.border,
                    width: picked ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      picked
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: picked ? MateColors.pink : MateColors.rose,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        q.options[i],
                        style: const TextStyle(
                          fontSize: 14,
                          color: MateColors.plum,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _revealPanel(_QuizQ q, bool match) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MateRadius.card),
        border: Border.all(
          color: match ? const Color(0xFF22C55E) : const Color(0xFFE11D48),
          width: 2,
        ),
        boxShadow: MateShadows.soft,
      ),
      child: Column(
        children: [
          Icon(
            match ? Icons.favorite_rounded : Icons.heart_broken_rounded,
            color: match ? MateColors.pinkDeep : const Color(0xFFE11D48),
            size: 56,
          ),
          const SizedBox(height: 8),
          Text(
            match ? 'Trùng ý! 💕' : 'Khác nhau rồi 😅',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: MateColors.plum,
            ),
          ),
          const SizedBox(height: 14),
          _compareRow('Bạn', q.options[_pickA ?? 0], MateColors.pink),
          const SizedBox(height: 6),
          _compareRow('Người yêu', q.options[_pickB ?? 0], const Color(0xFF9333EA)),
        ],
      ),
    );
  }

  Widget _compareRow(String who, String ans, Color c) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: c.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            who,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: c,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            ans,
            style: const TextStyle(
              fontSize: 14,
              color: MateColors.plum,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// 4. Thử thách cặp đôi (DailyChallengeGame)
// =====================================================================
class DailyChallengeGame extends StatefulWidget {
  const DailyChallengeGame({super.key});
  @override
  State<DailyChallengeGame> createState() => _DailyChallengeGameState();
}

class _Challenge {
  final String title;
  final String desc;
  final int coins;
  final IconData icon;
  final Color color;
  const _Challenge({
    required this.title,
    required this.desc,
    required this.coins,
    required this.icon,
    required this.color,
  });
}

class _DailyChallengeGameState extends State<DailyChallengeGame> {
  late final List<_Challenge> _list;
  late final List<bool> _done;

  @override
  void initState() {
    super.initState();
    _list = const [
      _Challenge(
        title: 'Gửi 3 sticker 💌',
        desc: 'Mỗi người gửi 3 sticker yêu thương hôm nay.',
        coins: 20,
        icon: Icons.send_rounded,
        color: MateColors.pink,
      ),
      _Challenge(
        title: 'Selfie cùng nhau 📸',
        desc: 'Chụp và lưu 1 bức ảnh chung hôm nay.',
        coins: 30,
        icon: Icons.photo_camera_rounded,
        color: Color(0xFF9333EA),
      ),
      _Challenge(
        title: 'Nói "Anh/Em yêu" 💕',
        desc: 'Bắt đầu cuộc trò chuyện bằng câu yêu thương.',
        coins: 15,
        icon: Icons.favorite_rounded,
        color: Color(0xFFE11D48),
      ),
      _Challenge(
        title: 'Đi dạo 15 phút 🚶‍♀️🚶',
        desc: 'Cùng nhau đi bộ 15 phút, chia sẻ chuyện trong ngày.',
        coins: 25,
        icon: Icons.directions_walk_rounded,
        color: Color(0xFF0D9488),
      ),
      _Challenge(
        title: 'Nấu ăn cùng nhau 🍳',
        desc: 'Cùng chuẩn bị 1 bữa ăn nhỏ tại nhà.',
        coins: 40,
        icon: Icons.restaurant_rounded,
        color: Color(0xFFD97706),
      ),
      _Challenge(
        title: 'Nghe 1 bài hát chung 🎧',
        desc: 'Nghe chung 1 bài hát và chia sẻ cảm nhận.',
        coins: 10,
        icon: Icons.music_note_rounded,
        color: Color(0xFF0284C7),
      ),
    ];
    _done = List.filled(_list.length, false);
  }

  int get _totalCoins => _list
      .asMap()
      .entries
      .where((e) => _done[e.key])
      .fold(0, (sum, e) => sum + e.value.coins);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFB1CB), Color(0xFFFFD8E4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(MateRadius.card),
            boxShadow: MateShadows.hero,
          ),
          child: Row(
            children: [
              const Icon(Icons.monetization_on_rounded,
                  color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Xu cặp đôi hôm nay',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_totalCoins xu',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(MateRadius.pill),
                ),
                child: Text(
                  '${_done.where((d) => d).length}/${_list.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ...List.generate(_list.length, (i) {
          final c = _list[i];
          final done = _done[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(MateRadius.card),
                border: Border.all(
                  color: done ? const Color(0xFF22C55E) : MateColors.border,
                  width: done ? 1.5 : 1,
                ),
                boxShadow: MateShadows.soft,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: done
                          ? const Color(0xFFDCFCE7)
                          : c.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      done ? Icons.check_rounded : c.icon,
                      color: done ? const Color(0xFF22C55E) : c.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.title,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: MateColors.plum,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c.desc,
                          style: TextStyle(
                            fontSize: 12,
                            color: MateColors.plum.withOpacity(0.65),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.monetization_on_rounded,
                                color: Color(0xFFEAB308), size: 14),
                            const SizedBox(width: 3),
                            Text(
                              '+${c.coins} xu',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: done
                        ? null
                        : () => setState(() => _done[i] = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: done
                          ? const Color(0xFFDCFCE7)
                          : MateColors.pink,
                      foregroundColor: done
                          ? const Color(0xFF22C55E)
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(MateRadius.pill),
                      ),
                      minimumSize: const Size(0, 0),
                    ),
                    child: Text(
                      done ? 'Xong' : 'Nhận',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE0EA).withOpacity(0.3),
            borderRadius: BorderRadius.circular(MateRadius.card),
            border: Border.all(
              color: const Color(0xFFFFE0EA),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: MateColors.rose, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Xu sẽ tích hợp với Pet và thành tích cặp đôi ở phiên bản tiếp theo.',
                  style: TextStyle(
                    fontSize: 12,
                    color: MateColors.plum.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// Shared intro & result panels
// =====================================================================

class GameIntro extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String ctaLabel;
  final VoidCallback onCta;

  const GameIntro({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.ctaLabel,
    required this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            shape: BoxShape.circle,
            boxShadow: MateShadows.soft,
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor, size: 56),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: MateColors.plum,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          description,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: MateColors.plum.withOpacity(0.7),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onCta,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(ctaLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: MateColors.pink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MateRadius.pill),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class GameResult extends StatelessWidget {
  final IconData icon;
  final String title;
  final String scoreText;
  final String subtitle;
  final VoidCallback onPlayAgain;

  const GameResult({
    super.key,
    required this.icon,
    required this.title,
    required this.scoreText,
    required this.subtitle,
    required this.onPlayAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: MateColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: MateShadows.cta,
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 64),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: MateColors.plum,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          scoreText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: MateColors.pink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: MateColors.plum.withOpacity(0.7),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onPlayAgain,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Chơi lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: MateColors.pink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MateRadius.pill),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: MateColors.pink,
              side: const BorderSide(color: MateColors.pink, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MateRadius.pill),
              ),
            ),
            child: const Text(
              'Quay lại danh sách',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}
