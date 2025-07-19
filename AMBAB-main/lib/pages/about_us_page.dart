import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About us"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "عن شركتنا",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "نحن شركة رائدة في صناعة الزراعة، نقدم منتجات وخدمات عالية الجودة لعملائنا. مهمتنا هي الابتكار وقيادة السوق بحلول مستدامة وفعالة",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              "رؤيتنا",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              "أن نكون الشركة الأكثر ثقة وابتكارًا في قطاع الزراعة، ملتزمين بتحسين حياة المزارعين والمستهلكين على حد سواء",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
