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

        $order = 0;

        $this->make('General Knowledge', 'Test your everyday knowledge.', 'easy', ++$order, [
            ['What is the capital of Pakistan?', ['Karachi', 'Lahore', 'Islamabad', 'Peshawar'], 2, 'Islamabad has been the capital since 1967.'],
            ['How many continents are there on Earth?', ['5', '6', '7', '8'], 2, 'There are 7 continents.'],
            ['Which planet is known as the Red Planet?', ['Venus', 'Mars', 'Jupiter', 'Saturn'], 1, 'Mars appears red due to iron oxide.'],
            ['What is the largest ocean on Earth?', ['Atlantic', 'Indian', 'Arctic', 'Pacific'], 3, 'The Pacific is the largest and deepest ocean.'],
            ['Who wrote the national anthem of Pakistan?', ['Allama Iqbal', 'Hafeez Jalandhari', 'Faiz Ahmed Faiz', 'Josh Malihabadi'], 1, 'Hafeez Jalandhari wrote the lyrics in 1952.'],
        ]);

        $this->make('Computer Science Basics', 'Fundamentals every CS student should know.', 'medium', ++$order, [
            ['What does CPU stand for?', ['Central Processing Unit', 'Computer Personal Unit', 'Central Process Utility', 'Control Processing Unit'], 0, 'CPU = Central Processing Unit.'],
            ['Which data structure uses FIFO order?', ['Stack', 'Queue', 'Tree', 'Graph'], 1, 'A Queue is First-In-First-Out.'],
            ['What is the time complexity of binary search?', ['O(n)', 'O(n^2)', 'O(log n)', 'O(1)'], 2, 'Binary search halves the range each step → O(log n).'],
            ['Which of these is a protocol, not a programming language?', ['Python', 'HTTP', 'Java', 'Dart'], 1, 'HTTP is a protocol, not a programming language.'],
            ['What does RAM stand for?', ['Read Access Memory', 'Random Access Memory', 'Rapid Access Module', 'Run And Manage'], 1, 'RAM = Random Access Memory.'],
        ]);

        $this->make('Islamic Studies', 'Basic Islamic knowledge.', 'easy', ++$order, [
            ['How many pillars of Islam are there?', ['3', '4', '5', '6'], 2, 'There are 5 pillars of Islam.'],
            ['In which month do Muslims fast?', ['Shaban', 'Ramadan', 'Rajab', 'Muharram'], 1, 'Fasting is observed in Ramadan.'],
            ['How many times do Muslims pray each day?', ['3', '4', '5', '6'], 2, 'Five obligatory prayers each day.'],
            ['Which is the holy book of Islam?', ['Torah', 'Bible', 'Quran', 'Zabur'], 2, 'The Quran is the holy book of Islam.'],
            ['Towards which city do Muslims face during prayer?', ['Madinah', 'Makkah', 'Jerusalem', 'Taif'], 1, 'Muslims face the Kaaba in Makkah.'],
        ]);

        $this->make('English Grammar', 'Sharpen your grammar.', 'medium', ++$order, [
            ['Choose the correct article: "___ honest man".', ['A', 'An', 'The', 'No article'], 1, '"Honest" begins with a vowel sound, so "an".'],
            ['What is the past tense of "go"?', ['Goed', 'Gone', 'Went', 'Going'], 2, 'The simple past of "go" is "went".'],
            ['Which word is a pronoun: "She sings beautifully."', ['She', 'sings', 'beautifully', 'None'], 0, '"She" is a pronoun acting as the subject.'],
            ['Which is a synonym of "happy"?', ['Sad', 'Joyful', 'Angry', 'Tired'], 1, '"Joyful" means happy.'],
            ['Choose the correct spelling.', ['Recieve', 'Receive', 'Receeve', 'Receiv'], 1, 'Remember: "i before e except after c".'],
        ]);

        $this->make('Mathematics Basics', 'Everyday maths essentials.', 'easy', ++$order, [
            ['What is 7 × 8?', ['54', '56', '48', '64'], 1, '7 × 8 = 56.'],
            ['What is 25% of 200?', ['25', '50', '75', '100'], 1, '25% of 200 = 50.'],
            ['The value of π (pi) rounded to two decimals is?', ['3.12', '3.14', '3.16', '3.18'], 1, 'π ≈ 3.14.'],
            ['How many sides does a triangle have?', ['2', '3', '4', '5'], 1, 'A triangle has 3 sides.'],
            ['What is 15 + 27?', ['42', '41', '43', '40'], 0, '15 + 27 = 42.'],
        ]);

        $this->make('World Geography', 'Places, rivers and mountains.', 'medium', ++$order, [
            ['Which is the largest country by area?', ['Canada', 'China', 'Russia', 'USA'], 2, 'Russia is the largest country by land area.'],
            ['Which river is traditionally considered the longest in the world?', ['Amazon', 'Nile', 'Yangtze', 'Mississippi'], 1, 'The Nile is traditionally regarded as the longest river.'],
            ['Mount Everest lies in which mountain range?', ['Andes', 'Alps', 'Himalayas', 'Rockies'], 2, 'Everest is in the Himalayas.'],
            ['The Sahara Desert is located on which continent?', ['Asia', 'Africa', 'Australia', 'South America'], 1, 'The Sahara is in northern Africa.'],
            ['The Great Barrier Reef is off the coast of?', ['Brazil', 'Australia', 'India', 'Mexico'], 1, 'It lies off the coast of Australia.'],
        ]);

        $this->make('General Science', 'Quick science facts.', 'easy', ++$order, [
            ['Which gas do plants absorb from the air for photosynthesis?', ['Oxygen', 'Carbon dioxide', 'Nitrogen', 'Hydrogen'], 1, 'Plants absorb carbon dioxide.'],
            ['What is H₂O commonly known as?', ['Salt', 'Water', 'Hydrogen', 'Oxygen'], 1, 'H₂O is water.'],
            ['How many bones are in the adult human body?', ['196', '206', '216', '226'], 1, 'An adult human has 206 bones.'],
            ['Which organ pumps blood around the body?', ['Liver', 'Lungs', 'Heart', 'Kidney'], 2, 'The heart pumps blood.'],
            ['Which force pulls objects toward the Earth?', ['Magnetism', 'Gravity', 'Friction', 'Tension'], 1, 'Gravity pulls objects toward Earth.'],
        ]);

        $this->make('Pakistan Studies', 'Know your country.', 'easy', ++$order, [
            ['In which year did Pakistan gain independence?', ['1945', '1947', '1950', '1956'], 1, 'Pakistan gained independence in 1947.'],
            ['Who is the founder of Pakistan?', ['Allama Iqbal', 'Liaquat Ali Khan', 'Quaid-e-Azam M. Ali Jinnah', 'Sir Syed Ahmad Khan'], 2, 'Quaid-e-Azam Muhammad Ali Jinnah founded Pakistan.'],
            ['What is the national language of Pakistan?', ['Punjabi', 'Urdu', 'Sindhi', 'Pashto'], 1, 'Urdu is the national language.'],
            ['Which is the largest province of Pakistan by area?', ['Punjab', 'Sindh', 'Balochistan', 'Khyber Pakhtunkhwa'], 2, 'Balochistan is the largest by area.'],
            ['The national flower of Pakistan is?', ['Rose', 'Jasmine', 'Tulip', 'Sunflower'], 1, 'Jasmine (Chambeli) is the national flower.'],
        ]);

        $this->make('Everyday Arithmetic', 'Mental maths warm-up.', 'easy', ++$order, [
            ['What is 100 ÷ 4?', ['20', '25', '30', '40'], 1, '100 ÷ 4 = 25.'],
            ['Half of 90 is?', ['40', '45', '50', '55'], 1, 'Half of 90 = 45.'],
            ['What is 9 × 9?', ['72', '81', '90', '99'], 1, '9 × 9 = 81.'],
            ['One dozen equals how many?', ['10', '11', '12', '13'], 2, 'A dozen = 12.'],
            ['What is 1000 − 250?', ['650', '700', '750', '800'], 2, '1000 − 250 = 750.'],
        ]);

        $this->make('Biology Basics', 'Life sciences fundamentals.', 'medium', ++$order, [
            ['What is the basic unit of life?', ['Atom', 'Cell', 'Tissue', 'Organ'], 1, 'The cell is the basic unit of life.'],
            ['Which part of a plant mainly carries out photosynthesis?', ['Root', 'Stem', 'Leaf', 'Flower'], 2, 'Leaves carry out most photosynthesis.'],
            ['Humans breathe in oxygen and breathe out mostly?', ['Nitrogen', 'Carbon dioxide', 'Hydrogen', 'Helium'], 1, 'We exhale carbon dioxide.'],
            ['What is often called the "powerhouse of the cell"?', ['Nucleus', 'Mitochondria', 'Ribosome', 'Cytoplasm'], 1, 'Mitochondria produce energy (ATP).'],
            ['Which blood cells mainly help fight infection?', ['Red blood cells', 'White blood cells', 'Platelets', 'Plasma'], 1, 'White blood cells fight infection.'],
        ]);

        $this->make('Chemistry Basics', 'Elements and reactions.', 'medium', ++$order, [
            ['What is the chemical symbol for gold?', ['Gd', 'Au', 'Ag', 'Go'], 1, 'Gold is "Au" (from Latin aurum).'],
            ['The most abundant gas in Earth\'s atmosphere is?', ['Oxygen', 'Carbon dioxide', 'Nitrogen', 'Argon'], 2, 'Nitrogen makes up about 78% of air.'],
            ['What is the pH of pure water?', ['5', '7', '9', '11'], 1, 'Pure water is neutral, pH 7.'],
            ['Which of these is a noble gas?', ['Oxygen', 'Hydrogen', 'Helium', 'Chlorine'], 2, 'Helium is a noble (inert) gas.'],
            ['The chemical symbol for sodium is?', ['So', 'Sd', 'Na', 'Nm'], 2, 'Sodium is "Na" (from Latin natrium).'],
        ]);

        $this->make('Physics Basics', 'Forces, energy and motion.', 'medium', ++$order, [
            ['What is the SI unit of force?', ['Joule', 'Newton', 'Watt', 'Pascal'], 1, 'Force is measured in newtons (N).'],
            ['Light travels at approximately?', ['300 km/s', '3,000 km/s', '300,000 km/s', '3,000,000 km/s'], 2, 'Light travels ~300,000 km per second.'],
            ['Who proposed the law of universal gravitation?', ['Einstein', 'Newton', 'Galileo', 'Tesla'], 1, 'Isaac Newton formulated universal gravitation.'],
            ['The SI unit of electric current is?', ['Volt', 'Ampere', 'Ohm', 'Watt'], 1, 'Current is measured in amperes (A).'],
            ['A moving object possesses which type of energy?', ['Potential', 'Kinetic', 'Chemical', 'Thermal'], 1, 'Motion gives kinetic energy.'],
        ]);

        $this->make('World History', 'Key moments in history.', 'medium', ++$order, [
            ['In which year did World War II end?', ['1939', '1945', '1950', '1918'], 1, 'World War II ended in 1945.'],
            ['Who was the first President of the United States?', ['Abraham Lincoln', 'George Washington', 'Thomas Jefferson', 'John Adams'], 1, 'George Washington was the first U.S. President.'],
            ['The Great Wall is located in which country?', ['India', 'China', 'Japan', 'Egypt'], 1, 'The Great Wall is in China.'],
            ['The famous ancient pyramids of Giza are in?', ['Iraq', 'Egypt', 'Greece', 'Mexico'], 1, 'The pyramids of Giza are in Egypt.'],
            ['Who is credited with reaching the Americas in 1492?', ['Vasco da Gama', 'Christopher Columbus', 'Ferdinand Magellan', 'Marco Polo'], 1, 'Columbus reached the Americas in 1492.'],
        ]);

        $this->make('Logical Reasoning', 'Patterns and puzzles.', 'medium', ++$order, [
            ['Which is the odd one out: 3, 5, 8, 11?', ['3', '5', '8', '11'], 2, '8 is the only even number.'],
            ['Complete the series: A, C, E, G, ?', ['H', 'I', 'J', 'K'], 1, 'Skip one letter each time → I.'],
            ['Find the next number: 2, 4, 8, 16, ?', ['24', '30', '32', '64'], 2, 'Each number doubles → 32.'],
            ['Complete the series: 1, 4, 9, 16, ?', ['20', '25', '24', '36'], 1, 'These are squares: 5² = 25.'],
            ['If each letter is shifted +1 (A→B), what is the code for "CAT"?', ['DBU', 'DBT', 'EBU', 'DCU'], 0, 'C→D, A→B, T→U = DBU.'],
        ]);

        $this->make('General Awareness', 'A bit of everything.', 'easy', ++$order, [
            ['How many players from one team are on the field in football (soccer)?', ['9', '10', '11', '12'], 2, 'Each side fields 11 players.'],
            ['Which is the smallest prime number?', ['0', '1', '2', '3'], 2, '2 is the smallest (and only even) prime.'],
            ['How many days are in a leap year?', ['364', '365', '366', '367'], 2, 'A leap year has 366 days.'],
            ['The currency of Pakistan is the?', ['Rupee', 'Dollar', 'Taka', 'Riyal'], 0, 'Pakistan uses the Rupee.'],
            ['How many colours are in a rainbow?', ['5', '6', '7', '8'], 2, 'A rainbow has 7 colours (VIBGYOR).'],
        ]);

        $this->command->info('Done: ' . Quiz::count() . ' quizzes, ' . QuizQuestion::count() . ' questions.');
    }

    private function make(string $title, string $description, string $difficulty, int $order, array $questions): void
    {
        $quiz = Quiz::create([
            'title' => $title,
            'description' => $description,
            // Demo quizzes are program-wide (shown in "Test your knowledge"),
            // general (no category) so every user can take them.
            'scope' => 'program',
            'category_id' => null,
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
