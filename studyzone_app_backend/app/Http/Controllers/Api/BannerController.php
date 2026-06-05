<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\BannerResource;
use App\Models\Banner;
use App\Traits\ApiResponse;

class BannerController extends Controller
{
    use ApiResponse;

    /**
     * Active promotional/announcement banners for the Home screen carousel.
     */
    public function index()
    {
        try {
            $banners = Banner::active()
                ->orderBy('sort_order')
                ->orderByDesc('id')
                ->get();

            return $this->successResponse(
                BannerResource::collection($banners),
                'Banners retrieved successfully'
            );
        } catch (\Exception $e) {
            return $this->serverErrorResponse(
                'Failed to retrieve banners',
                config('app.debug') ? $e->getMessage() : null
            );
        }
    }
}
