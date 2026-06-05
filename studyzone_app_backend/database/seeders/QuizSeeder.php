<?php

namespace Database\Seeders;

use App\Models\Quiz;
use App\Models\QuizQuestion;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Schema;

class QuizSeeder extends Seeder
{
    public function run(): void
    {
        Schema::disableForeignKeyConstraints();
        if (Schema::hasTable('quiz_attempts')) {
            \App\Models\QuizAttempt::truncate();
        }
        QuizQuestion::truncate();
        Quiz::truncate();
        Schema::enableForeignKeyConstraints();

        $this->command->info('Seeding demo quizzes…');

        $this->make('General Knowledge', 'Test your everyday knowledge.', 'easy', 1, [
            ['What is the capital of Pakistan?', ['Karachi', 'Lahore', 'Islamabad', 'Peshawar'], 2, 'Islamabad has been the capital since 1967.'],
            ['How many continents are there on Earth?', ['5', '6', '7', '8'], 2, 'There are 7 continents.'],
            ['Which planet is known as the Red Planet?', ['Venus', 'Mars', 'Jupiter', 'Saturn'], 1, 'Mars appears red due to iron oxide.'],
            ['What is the largest ocean on Earth?', ['Atlantic', 'Indian', 'Arctic', 'Pacific'], 3, 'The Pacific is the largest and deepest ocean.'],
            ['Who wrote the national anthem of Pakistan?', ['Allama Iqbal', 'Hafeez Jalandhari', 'Faiz Ahmed Faiz', 'Josh Malihabadi'], 1, 'Hafeez Jalandhari wrote the lyrics in 1952.'],
        ]);

        $this->make('Computer Science Basics', 'Fundamentals every CS student should know.', 'medium', 2, [
            ['What does CPU stand for?', ['Central Processing Unit', 'Computer Personal Unit', 'Central Process Utility', 'Control Processing Unit'], 0, 'CPU = Central Processing Unit.'],
            ['Which data structure uses FIFO order?', ['Stack', 'Queue', 'Tree', 'Graph'], 1, 'A Queue is First-In-First-Out.'],
            ['What is the time complexity of binary search?', ['O(n)', 'O(n^2)', 'O(log n)', 'O(1)'], 2, 'Binary search halves the range each step → O(log n).'],
            ['Which of these is NOT a programming language?', ['Python', 'HTTP', 'Java', 'Dart'], 1, 'HTTP is a protocol, not a programming language.'],
            ['What does RAM stand for?', ['Read Access Memory', 'Random Access Memory', 'Rapid Access Module', 'Run And Manage'], 1, 'RAM = Random Access Memory.'],
        ]);

        $this->make('Islamic Studies', 'Basic Islamic knowledge.', 'easy', 3, [
            ['How many pillars of Islam are there?', ['3', '4', '5', '6'], 2, 'There are 5 pillars of Islam.'],
            ['In which month do Muslims fast?', ['Shaban', 'Ramadan', 'Rajab', 'Muharram'], 1, 'Fasting is observed in Ramadan.'],
            ['How many times do Muslims pray each day?', ['3', '4', '5', '6'], 2, 'Five obligatory prayers each day.'],
            ['Which is the holy book of Islam?', ['Torah', 'Bible', 'Quran', 'Zabur'], 2, 'The Quran is the holy book of Islam.'],
            ['Towards which city do Muslims face during prayer?', ['Madinah', 'Makkah', 'Jerusalem', 'Taif'], 1, 'Muslims face the Kaaba in Makkah.'],
        ]);

        $this->make('English Grammar', 'Sharpen your grammar.', 'medium', 4, [
            ['Choose the correct article: "___ honest man".', ['A', 'An', 'The', 'No article'], 1, '"Honest" begins with a vowel sound, so "an".'],
            ['What is the past tense of "go"?', ['Goed', 'Gone', 'Went', 'Going'], 2, 'The simple past of "go" is "went".'],
            ['Identify the noun: "She sings beautifully."', ['She', 'sings', 'beautifully', 'None'], 0, '"She" is a pronoun acting as the subject/noun.'],
            ['Which is a synonym of "happy"?', ['Sad', 'Joyful', 'Angry', 'Tired'], 1, '"Joyful" means happy.'],
            ['Choose the correct spelling.', ['Recieve', 'Receive', 'Receeve', 'Receiv'], 1, 'Remember: "i before e except after c".'],
        ]);

        $this->command->info('Done: ' . Quiz::count() . ' quizzes, ' . QuizQuestion::count() . ' questions.');
    }

    private function make(string $title, string $description, string $difficulty, int $order, array $questions): void
    {
        $quiz = Quiz::create([
            'title' => $title,
            'description' => $description,
            'difficulty' => $difficulty,
            'is_active' => true,
            'sort_order' => $order,
        ]);

        foreach ($questions as $i => $q) {
            QuizQuestion::create([
                'quiz_id' => $quiz->id,
                'question' => $q[0],
                'options' => $q[1],
                'correct_index' => $q[2],
                'explanation' => $q[3] ?? null,
                'sort_order' => $i,
            ]);
        }
    }
}
