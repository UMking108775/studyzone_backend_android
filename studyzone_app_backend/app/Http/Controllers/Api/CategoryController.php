<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\CategoryResource;
use App\Models\Category;
use App\Traits\ApiResponse;
use Illuminate\Http\Request;

class CategoryController extends Controller
{
    use ApiResponse;

    /**
     * Get all main categories (level 1) that user has access to
     */
    public function index(Request $request)
    {
        try {
            $user = auth('sanctum')->user();

            if (!$user && $request->bearerToken()) {
                 return $this->unauthorizedResponse('Unauthenticated');
            }
            
            // Return ALL active level 1 categories. Paid/locked ones are shown
            // with an `is_locked` flag (see CategoryResource) so the app can
            // display a lock badge + request-access; their CONTENT stays gated
            // server-side in ContentController.
            $categories = Category::active()
                ->byLevel(1)
                ->with(['children' => fn ($q) => $q->orderBy('sort_order')->orderBy('created_at')->orderBy('id')])
                ->withCount('contents')
                ->orderBy('sort_order')
                ->orderBy('created_at')
                ->orderBy('id')
                ->get();

            return $this->successResponse(
                CategoryResource::collection($categories),
                'Main categories retrieved successfully'
            );

        } catch (\Exception $e) {
            return $this->serverErrorResponse(
                'Failed to retrieve categories',
                config('app.debug') ? $e->getMessage() : null
            );
        }
    }

    /**
     * Get subcategories for a specific parent category
     */
    public function subcategories(Request $request, $parentId)
    {
        try {
            $user = auth('sanctum')->user();

            if (!$user && $request->bearerToken()) {
                 return $this->unauthorizedResponse('Unauthenticated');
            }

            // Verify parent category exists and is active
            $parent = Category::active()->find($parentId);

            if (!$parent) {
                return $this->notFoundResponse('Parent category not found or inactive');
            }

            // Return ALL active subcategories with their `is_locked` flag so the
            // app can render lock badges. Browsing the tree structure is allowed;
            // the actual CONTENT remains gated in ContentController.
            $subcategories = Category::active()
                ->where('parent_id', $parentId)
                ->with(['children' => fn ($q) => $q->orderBy('sort_order')->orderBy('created_at')->orderBy('id')])
                ->withCount('contents')
                ->orderBy('sort_order')
                ->orderBy('created_at')
                ->orderBy('id')
                ->get();

            return $this->successResponse(
                CategoryResource::collection($subcategories),
                'Subcategories retrieved successfully'
            );

        } catch (\Exception $e) {
            return $this->serverErrorResponse(
                'Failed to retrieve subcategories',
                config('app.debug') ? $e->getMessage() : null
            );
        }
    }

    /**
     * Get a specific category by ID
     */
    public function show(Request $request, $id)
    {
        try {
            $user = auth('sanctum')->user();

            if (!$user && $request->bearerToken()) {
                 return $this->unauthorizedResponse('Unauthenticated');
            }

            // Check if user has access to this category (if authenticated)
            if ($user && !$user->hasAccessToCategoryAndParents($id)) {
                return $this->unauthorizedResponse('You do not have access to this category');
            }

            $category = Category::active()
                ->with(['parent', 'children'])
                ->withCount('contents')
                ->find($id);

            if (!$category) {
                return $this->notFoundResponse('Category not found or inactive');
            }

            // Filter children based on user access (if authenticated)
            if ($user && $category->children) {
                $category->children = $category->children->filter(function ($child) use ($user) {
                    return $user->hasAccessToCategory($child->id);
                });
            }

            return $this->successResponse(
                new CategoryResource($category),
                'Category retrieved successfully'
            );

        } catch (\Exception $e) {
            return $this->serverErrorResponse(
                'Failed to retrieve category',
                config('app.debug') ? $e->getMessage() : null
            );
        }
    }

    /**
     * Get full category tree that user has access to
     */
    public function tree(Request $request)
    {
        try {
            $user = auth('sanctum')->user();

            if (!$user && $request->bearerToken()) {
                 return $this->unauthorizedResponse('Unauthenticated');
            }

            // Root categories with the full nested tree (unlimited depth)
            $categories = Category::active()
                ->whereNull('parent_id')
                ->withCount('contents')
                ->with('childrenRecursive')
                ->get();

            $tree = $user
                ? $this->filterTreeByAccess($categories, $user)
                : $categories;

            return $this->successResponse(
                CategoryResource::collection($tree),
                'Category tree retrieved successfully'
            );

        } catch (\Exception $e) {
            return $this->serverErrorResponse(
                'Failed to retrieve category tree',
                config('app.debug') ? $e->getMessage() : null
            );
        }
    }

    /**
     * Recursively keep only the categories (at any depth) the user can access.
     */
    private function filterTreeByAccess($categories, $user)
    {
        return $categories->filter(function ($category) use ($user) {
            if (!$user->hasAccessToCategory($category->id)) {
                return false;
            }
            if ($category->relationLoaded('childrenRecursive')) {
                $category->setRelation(
                    'childrenRecursive',
                    $this->filterTreeByAccess($category->childrenRecursive, $user)
                );
            }
            return true;
        })->values();
    }
}

