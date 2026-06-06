<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Category extends Model
{
    protected $fillable = [
        'title',
        'image',
        'parent_id',
        'is_active',
        'level',
        'is_free',
        'sort_order',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'level' => 'integer',
        'is_free' => 'boolean',
        'sort_order' => 'integer',
    ];

    protected static function booted(): void
    {
        // When a category is deleted, its lesson-specific quizzes would have
        // category_id nulled (nullOnDelete) and then match neither the category
        // content list nor "Test your knowledge". Fall them back to program
        // scope so they stay reachable (as general quizzes) instead of vanishing.
        static::deleting(function (Category $category) {
            Quiz::where('category_id', $category->id)
                ->where('scope', 'lesson')
                ->update(['scope' => 'program']);
        });
    }

    /**
     * Get the parent category.
     */
    public function parent(): BelongsTo
    {
        return $this->belongsTo(Category::class, 'parent_id');
    }

    /**
     * Get the child categories.
     */
    public function children(): HasMany
    {
        return $this->hasMany(Category::class, 'parent_id');
    }

    /**
     * Get all descendants recursively.
     */
    public function descendants(): HasMany
    {
        return $this->children()->with('descendants');
    }

    /**
     * Recursively eager-load children to ANY depth, with their content counts.
     * Used to return the full nested category tree to the app.
     */
    public function childrenRecursive(): HasMany
    {
        return $this->children()
            ->where('is_active', true)
            ->withCount('contents')
            ->orderBy('sort_order')
            ->orderBy('created_at')
            ->orderBy('id')
            ->with('childrenRecursive');
    }

    /**
     * Recursive children for the ADMIN tree view (includes inactive, with
     * children + content counts), so categories of any depth render in one view.
     */
    public function childrenRecursiveAdmin(): HasMany
    {
        return $this->children()
            ->withCount(['children', 'contents'])
            ->with('childrenRecursiveAdmin')
            ->orderBy('sort_order')
            ->orderBy('id');
    }

    /**
     * Get the contents for the category.
     */
    public function contents(): HasMany
    {
        return $this->hasMany(Content::class);
    }

    /**
     * Scope to get only active categories.
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    /**
     * Scope to get categories by level.
     */
    public function scopeByLevel($query, int $level)
    {
        return $query->where('level', $level);
    }

    /**
     * Get the users who have access to this category.
     */
    public function userAccess()
    {
        return $this->hasMany(CategoryAccess::class);
    }

    /**
     * Get all users with their access status for this category.
     */
    public function usersWithAccess()
    {
        return $this->belongsToMany(User::class, 'user_category_access')
                    ->withPivot('has_access')
                    ->withTimestamps();
    }
}
