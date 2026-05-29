import 'package:flutter/material.dart';
import 'flutter_builtin_keyboard_demo.dart';
import 'keyboard_animation_demo.dart';
import 'keyboard_avoiding_demo.dart';
import 'keyboard_aware_form_demo.dart';
import 'keyboard_aware_scroll_demo.dart';
import 'keyboard_chat_demo.dart';
import 'keyboard_state_demo.dart';
import 'keyboard_sticky_demo.dart';
import 'keyboard_toolbar_demo.dart';
import 'keyboard_toolbar_form_demo.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final demos = <_Demo>[
      _Demo(
        title: 'Flutter Built-in (compare)',
        subtitle: 'resizeToAvoidBottomInset: true — no auto-scroll',
        icon: Icons.compare_arrows,
        color: Colors.red,
        screen: const FlutterBuiltinKeyboardDemo(),
      ),
      _Demo(
        title: 'KeyboardAvoidingView',
        subtitle: 'padding / height / position / translateWithPadding',
        icon: Icons.keyboard_alt_outlined,
        color: Colors.deepPurple,
        screen: const KeyboardAvoidingDemo(),
      ),
      _Demo(
        title: 'KeyboardAwareScrollView',
        subtitle: 'Auto-scrolls to keep focused input above keyboard',
        icon: Icons.unfold_more,
        color: Colors.indigo,
        screen: const KeyboardAwareScrollDemo(),
      ),
      _Demo(
        title: 'KeyboardAwareScrollView — Form',
        subtitle: 'Multi-field form with cards + KeyboardScrollBoundary',
        icon: Icons.list_alt_outlined,
        color: Colors.indigo,
        screen: const KeyboardAwareFormDemo(),
      ),
      _Demo(
        title: 'KeyboardStickyView',
        subtitle: 'Input bar sticks to the top of the keyboard',
        icon: Icons.push_pin_outlined,
        color: Colors.teal,
        screen: const KeyboardStickyDemo(),
      ),
      _Demo(
        title: 'KeyboardToolbar',
        subtitle: 'Prev / Next / Done toolbar above keyboard',
        icon: Icons.keyboard_tab,
        color: Colors.orange,
        screen: const KeyboardToolbarDemo(),
      ),
      _Demo(
        title: 'KeyboardToolbar — Form',
        subtitle: 'Form + bottom sheets — tests toolbar hide/show',
        icon: Icons.keyboard_tab_outlined,
        color: Colors.orange,
        screen: const KeyboardToolbarFormDemo(),
      ),
      _Demo(
        title: 'KeyboardChatScrollView',
        subtitle: 'Chat UI — always / whenAtEnd / persistent / never',
        icon: Icons.chat_bubble_outline,
        color: Colors.green,
        screen: const KeyboardChatDemo(),
      ),
      _Demo(
        title: 'Keyboard Animation',
        subtitle: 'Live height, progress, isVisible — frame by frame',
        icon: Icons.animation,
        color: Colors.pink,
        screen: const KeyboardAnimationDemo(),
      ),
      _Demo(
        title: 'Keyboard State',
        subtitle: 'isVisible, dismiss, preload, setInputMode',
        icon: Icons.info_outline,
        color: Colors.blueGrey,
        screen: const KeyboardStateDemo(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('flutter_keyboard_controller'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: demos.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final demo = demos[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: demo.color.withAlpha(30),
                child: Icon(demo.icon, color: demo.color),
              ),
              title: Text(
                demo.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(demo.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => demo.screen),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Demo {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget screen;

  _Demo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.screen,
  });
}
