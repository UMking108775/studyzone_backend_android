<?php

namespace Database\Seeders;

use App\Models\SubscriptionPlan;
use Illuminate\Database\Seeder;

class SubscriptionPlanSeeder extends Seeder
{
    public function run(): void
    {
        $this->command->info('Seeding subscription plans…');

        $plans = [
            [
                'name' => 'Monthly',
                'description' => '1 month of full premium access.',
                'duration_days' => 30,
                'price' => 499,
                'currency' => 'PKR',
                'features' => [
                    'Unlimited access to all courses',
                    'Download study materials',
                    'Unlimited quiz attempts',
                ],
                'is_active' => true,
                'sort_order' => 1,
            ],
            [
                'name' => 'Quarterly',
                'description' => '3 months of premium access — save vs monthly.',
                'duration_days' => 90,
                'price' => 1299,
                'currency' => 'PKR',
                'features' => [
                    'Everything in Monthly',
                    'Save PKR 198 vs monthly',
                    'Priority email support',
                ],
                'is_active' => true,
                'sort_order' => 2,
            ],
            [
                'name' => '6 Months',
                'description' => '6 months of premium access at the best mid-term value.',
                'duration_days' => 180,
                'price' => 2399,
                'currency' => 'PKR',
                'features' => [
                    'Everything in Quarterly',
                    'Save PKR 595 vs monthly',
                    'Early access to new content',
                ],
                'is_active' => true,
                'sort_order' => 3,
            ],
            [
                'name' => 'Yearly',
                'description' => '12 months of premium access — best value.',
                'duration_days' => 365,
                'price' => 3999,
                'currency' => 'PKR',
                'features' => [
                    'Everything in 6 Months',
                    'Save PKR 1989 vs monthly',
                    'Priority support all year',
                ],
                'is_active' => true,
                'sort_order' => 4,
            ],
        ];

        foreach ($plans as $plan) {
            SubscriptionPlan::updateOrCreate(
                ['name' => $plan['name']],
                $plan
            );
        }

        $this->command->info('Subscription plans seeded: ' . SubscriptionPlan::count() . ' total.');
    }
}
