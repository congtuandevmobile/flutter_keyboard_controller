import 'package:flutter/material.dart';
import 'package:flutter_keyboard_controller/flutter_keyboard_controller.dart';

class KeyboardChatDemo extends StatefulWidget {
  const KeyboardChatDemo({super.key});

  @override
  State<KeyboardChatDemo> createState() => _KeyboardChatDemoState();
}

class _KeyboardChatDemoState extends State<KeyboardChatDemo> {
  KeyboardLiftBehavior _behavior = KeyboardLiftBehavior.whenAtEnd;
  final _inputController = TextEditingController();

  final List<_Message> _messages = List.generate(
    20,
    (i) => _Message(text: 'Message ${20 - i}', isMe: i.isEven),
  );

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.insert(0, _Message(text: text, isMe: true));
      _inputController.clear();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeAreaBottom = MediaQuery.of(context).viewPadding.bottom;
    // InputBar height: top-padding(8) + row(~40) + bottom-padding(8) + gap(16)
    const extraBottomPadding = 56.0 + 16.0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('KeyboardChatScrollView'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SegmentedButton<KeyboardLiftBehavior>(
              segments: const [
                ButtonSegment(
                  value: KeyboardLiftBehavior.always,
                  label: Text('always'),
                ),
                ButtonSegment(
                  value: KeyboardLiftBehavior.whenAtEnd,
                  label: Text('whenAtEnd'),
                ),
                ButtonSegment(
                  value: KeyboardLiftBehavior.persistent,
                  label: Text('persist'),
                ),
                ButtonSegment(
                  value: KeyboardLiftBehavior.never,
                  label: Text('never'),
                ),
              ],
              selected: {_behavior},
              onSelectionChanged: (s) => setState(() {
                _behavior = s.first;
              }),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: KeyboardChatScrollView(
              liftBehavior: _behavior,
              extraBottomPadding: extraBottomPadding,
              safeAreaBottom: safeAreaBottom,
              children: _messages
                  .map((m) => _MessageBubble(message: m))
                  .toList(),
            ),
          ),
          _AnimatedInputBar(
            behavior: _behavior,
            child: _InputBar(controller: _inputController, onSend: _send),
          ),
        ],
      ),
    );
  }
}

class _AnimatedInputBar extends StatefulWidget {
  const _AnimatedInputBar({required this.behavior, required this.child});
  final KeyboardLiftBehavior behavior;
  final Widget child;

  @override
  State<_AnimatedInputBar> createState() => _AnimatedInputBarState();
}

class _AnimatedInputBarState extends State<_AnimatedInputBar> {
  double _persistentLift = 0;

  double _bottomFor(double keyboardH) {
    if (widget.behavior == KeyboardLiftBehavior.persistent) {
      if (keyboardH > 0) _persistentLift = keyboardH;
      return _persistentLift;
    }
    _persistentLift = 0;
    return keyboardH;
  }

  @override
  void didUpdateWidget(_AnimatedInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.behavior != widget.behavior) _persistentLift = 0;
  }

  @override
  Widget build(BuildContext context) {
    final animation = KeyboardControllerScope.maybeOf(context);
    return ValueListenableBuilder<double>(
      valueListenable: animation?.heightNotifier ?? _kZero,
      child: widget.child,
      builder: (_, keyboardH, child) => Positioned(
        left: 0,
        right: 0,
        bottom: _bottomFor(keyboardH),
        child: child!,
      ),
    );
  }
}

final _kZero = ValueNotifier(0.0);

class _Message {
  final String text;
  final bool isMe;
  _Message({required this.text, required this.isMe});
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final _Message message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.72,
        ),
        decoration: BoxDecoration(
          color: message.isMe
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isMe
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Message…',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: onSend,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
