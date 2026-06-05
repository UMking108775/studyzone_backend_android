<?php

namespace Database\Seeders;

use App\Models\Banner;
use App\Models\Category;
use App\Models\Content;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Comprehensive demo data for verifying the app end-to-end.
 *
 * Builds a deeply-nested category tree (matching the reference outline) and
 * fills leaf/branch categories with EVERY content type the app understands:
 * pdf, audio, video, image, doc, ppt, zip, link and rich_text (HTML body, e.g.
 * the Admission / Fee Structure pages).
 *
 * Run with:  php artisan db:seed --class=DemoContentSeeder
 *
 * WARNING: this truncates the categories, contents and user_category_access
 * tables first so the demo tree is clean. Use on dev / staging data only.
 */
class DemoContentSeeder extends Seeder
{
    // Public sample media URLs (for testing only).
    private const PDF = 'https://www.africau.edu/images/default/sample.pdf';
    private const PDF2 = 'https://pdfobject.com/pdf/sample.pdf';
    private const AUDIO = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
    private const AUDIO2 = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3';
    private const VIDEO = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
    private const VIDEO2 = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4';
    private const IMAGE = 'https://picsum.photos/seed/studyzone/900/600';
    private const ZIP = 'https://file-examples.com/storage/fea570b16e/2017/02/zip_2MB.zip';

    public function run(): void
    {
        $this->command->info('Clearing existing categories & contents…');
        Schema::disableForeignKeyConstraints();
        Content::truncate();
        if (Schema::hasTable('user_category_access')) {
            DB::table('user_category_access')->truncate();
        }
        Category::truncate();
        if (Schema::hasTable('banners')) {
            Banner::truncate();
        }
        Schema::enableForeignKeyConstraints();

        $this->command->info('Seeding category tree & content…');

        // ── 1. Hangouts ─────────────────────────────────────────────
        $hangouts = $this->cat('Hangouts', null, $this->img('hangouts'));

        $vu = $this->cat('Virtual University', $hangouts, $this->img('vu'));
        $this->content($vu, 'rich_text', 'About Virtual University', null, $this->aboutVuHtml());
        $this->content($vu, 'pdf', 'VU Prospectus', self::PDF);
        $this->content($vu, 'video', 'VU Orientation', self::VIDEO);

        $aiou = $this->cat('Allama Iqbal Open University', $hangouts, $this->img('aiou'));

        $bs = $this->cat('BS Program', $aiou);
        $bscs = $this->cat('BS Computer Science', $bs);

        $sem1 = $this->cat('Semester 1', $bscs);
        $this->content($sem1, 'pdf', 'ICT - Handbook', self::PDF);
        $this->content($sem1, 'video', 'Intro to Programming', self::VIDEO);

        $sem2 = $this->cat('Semester 2', $bscs);
        $subject = $this->cat('Subject 0001 - Data Structures', $sem2);

        // Subject 0001 holds EVERY content type for thorough verification.
        $this->content($subject, 'rich_text', 'Lecture Notes (Rich Text)', null, $this->lectureNotesHtml());
        $this->content($subject, 'pdf', 'Chapter 1 - Arrays', self::PDF);
        $this->content($subject, 'pdf', 'Chapter 2 - Linked Lists', self::PDF2);
        $this->content($subject, 'audio', 'Audio Lecture - Week 1', self::AUDIO);
        $this->content($subject, 'audio', 'Audio Lecture - Week 2', self::AUDIO2);
        $this->content($subject, 'video', 'Recorded Class - Stacks & Queues', self::VIDEO2);
        $this->content($subject, 'image', 'Binary Tree Diagram', self::IMAGE);
        $this->content($subject, 'doc', 'Assignment 1', self::PDF);
        $this->content($subject, 'ppt', 'Slides - Sorting Algorithms', self::PDF);
        $this->content($subject, 'zip', 'Code Samples', self::ZIP);
        $this->content($subject, 'link', 'AIOU Official Website', 'https://www.aiou.edu.pk/');
        $this->content($subject, 'pdf', 'Hangouts', self::PDF);

        $bsIslamic = $this->cat('BS Islamic Studies', $bs);
        $this->content($bsIslamic, 'pdf', 'Islamic Studies - Notes', self::PDF);
        $this->content($bsIslamic, 'audio', 'Tajweed Lesson 1', self::AUDIO);

        $mphil = $this->cat('M Phil Program', $aiou);
        $this->content($mphil, 'rich_text', 'M Phil Admission Criteria', null, $this->mphilHtml());

        // ── 2. Video Lectures (FREE) ────────────────────────────────
        $videoLec = $this->cat('Video Lectures', null, $this->img('video'), true);
        $this->content($videoLec, 'video', 'Mathematics - Calculus Basics', self::VIDEO);
        $this->content($videoLec, 'video', 'Physics - Newton\'s Laws', self::VIDEO2);
        $this->content($videoLec, 'video', 'English - Essay Writing', self::VIDEO);

        // ── 3. Past Papers (FREE) ───────────────────────────────────
        $pastPaper = $this->cat('Past Papers', null, $this->img('paper'), true);
        $this->content($pastPaper, 'pdf', 'Past Paper 2023', self::PDF);
        $this->content($pastPaper, 'pdf', 'Past Paper 2022', self::PDF2);
        $this->content($pastPaper, 'pdf', 'Past Paper 2021', self::PDF);

        // ── 4. Admission / Fee Structure (FREE, rich text) ──────────
        $admission = $this->cat('Admission / Fee Structure', null, $this->img('admission'), true);
        $this->content($admission, 'rich_text', 'Admission Process', null, $this->admissionHtml());
        $this->content($admission, 'rich_text', 'Fee Structure 2025', null, $this->feeStructureHtml());

        // ── Home banners ────────────────────────────────────────────
        Banner::create([
            'title' => 'Welcome to Study Zone',
            'subtitle' => 'Access study materials, tools & education news',
            'image_url' => 'https://picsum.photos/seed/szbanner1/1000/420',
            'link_url' => null,
            'sort_order' => 1,
        ]);
        Banner::create([
            'title' => 'New: Past Papers 2025',
            'subtitle' => 'Free access — tap to explore',
            'image_url' => 'https://picsum.photos/seed/szbanner2/1000/420',
            'link_url' => null,
            'sort_order' => 2,
        ]);
        Banner::create([
            'title' => 'Admission Open',
            'subtitle' => 'Check the fee structure & process',
            'image_url' => 'https://picsum.photos/seed/szbanner3/1000/420',
            'link_url' => null,
            'sort_order' => 3,
        ]);

        // Grant ADMIN users access to every category so they can browse the
        // whole tree (incl. the paid "Hangouts" branch). Regular users get no
        // grants here, so they see Free categories unlocked and Paid ones locked
        // — exactly the freemium flow to verify.
        $this->command->info('Granting admin users access to all categories…');
        $now = now();
        $categoryIds = Category::pluck('id');
        $rows = [];
        foreach (User::where('role', 'admin')->pluck('id') as $userId) {
            foreach ($categoryIds as $categoryId) {
                $rows[] = [
                    'user_id' => $userId,
                    'category_id' => $categoryId,
                    'has_access' => true,
                    'created_at' => $now,
                    'updated_at' => $now,
                ];
            }
        }
        foreach (array_chunk($rows, 500) as $chunk) {
            DB::table('user_category_access')->insert($chunk);
        }

        // Demo quizzes & flashcards.
        $this->call(QuizSeeder::class);

        $cats = Category::count();
        $items = Content::count();
        $this->command->info("Done: {$cats} categories, {$items} content items seeded.");
    }

    // ── helpers ─────────────────────────────────────────────────────

    private function cat(
        string $title,
        ?Category $parent = null,
        ?string $image = null,
        bool $isFree = false,
    ): Category {
        return Category::create([
            'title' => $title,
            'parent_id' => $parent?->id,
            'level' => $parent ? $parent->level + 1 : 1,
            'image' => $image,
            'is_active' => true,
            'is_free' => $isFree,
        ]);
    }

    private function content(
        Category $category,
        string $type,
        string $title,
        ?string $url = null,
        ?string $body = null,
    ): Content {
        return Content::create([
            'category_id' => $category->id,
            'content_type' => $type,
            'title' => $title,
            'backblaze_url' => $url,
            'body' => $body,
            'is_active' => true,
        ]);
    }

    private function img(string $seed): string
    {
        return "https://picsum.photos/seed/{$seed}/400/300";
    }

    // ── rich-text bodies (HTML) ─────────────────────────────────────

    private function aboutVuHtml(): string
    {
        return <<<'HTML'
<h2>Virtual University of Pakistan</h2>
<p>The Virtual University offers affordable, high-quality education to students
across Pakistan and abroad through modern technology.</p>
<ul>
  <li>Fully online degree programs</li>
  <li>Recorded video lectures</li>
  <li>Flexible learning schedule</li>
</ul>
HTML;
    }

    private function lectureNotesHtml(): string
    {
        return <<<'HTML'
<h2>Data Structures — Week 1</h2>
<p><strong>Topic:</strong> Introduction to Arrays</p>
<p>An <em>array</em> is a collection of items stored at contiguous memory
locations. Key points:</p>
<ol>
  <li>Fixed size once declared</li>
  <li>Constant-time access by index <code>O(1)</code></li>
  <li>Insertion / deletion can be <code>O(n)</code></li>
</ol>
<blockquote>Tip: choose the right data structure for the problem.</blockquote>
HTML;
    }

    private function mphilHtml(): string
    {
        return <<<'HTML'
<h2>M Phil Admission Criteria</h2>
<ul>
  <li>16 years of education (BS / Master)</li>
  <li>Minimum 2.5 CGPA or 60% marks</li>
  <li>Entry test &amp; interview</li>
</ul>
HTML;
    }

    private function admissionHtml(): string
    {
        return <<<'HTML'
<h2>Admission Process</h2>
<p>Follow these steps to apply for admission:</p>
<ol>
  <li>Create an account on the admission portal.</li>
  <li>Fill in your personal &amp; academic details.</li>
  <li>Upload required documents (CNIC, photo, transcripts).</li>
  <li>Pay the admission processing fee.</li>
  <li>Submit and track your application status.</li>
</ol>
<h3>Required Documents</h3>
<ul>
  <li>Attested copies of educational certificates</li>
  <li>Copy of CNIC / B-Form</li>
  <li>Two passport-size photographs</li>
</ul>
HTML;
    }

    private function feeStructureHtml(): string
    {
        return <<<'HTML'
<h2>Fee Structure 2025</h2>
<table border="1" cellpadding="8" cellspacing="0" style="border-collapse:collapse;width:100%">
  <thead>
    <tr><th>Program</th><th>Admission Fee</th><th>Per Semester</th></tr>
  </thead>
  <tbody>
    <tr><td>BS Computer Science</td><td>Rs. 5,000</td><td>Rs. 25,000</td></tr>
    <tr><td>BS Islamic Studies</td><td>Rs. 5,000</td><td>Rs. 18,000</td></tr>
    <tr><td>M Phil</td><td>Rs. 8,000</td><td>Rs. 40,000</td></tr>
  </tbody>
</table>
<p><small>Fees are indicative and subject to change.</small></p>
HTML;
    }
}
