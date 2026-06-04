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
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'level' => 'integer',
    ];

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
            ->orderBy('title');
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
