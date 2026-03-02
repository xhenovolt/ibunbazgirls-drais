import React from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';

interface PaginationProps {
  currentPage: number;
  totalPages: number;
  onPageChange: (page: number) => void;
  totalItems: number;
  itemsPerPage: number;
}

const Pagination: React.FC<PaginationProps> = ({
  currentPage,
  totalPages,
  onPageChange,
  totalItems,
  itemsPerPage
}) => {
  const canGoPrev = currentPage > 1;
  const canGoNext = currentPage < totalPages;
  const startIndex = (currentPage - 1) * itemsPerPage + 1;
  const endIndex = Math.min(currentPage * itemsPerPage, totalItems);

  /**
   * Smart pagination: Show first, last, and nearby pages
   * Example: 1 ... 28 29 30 31 32 ... 50
   */
  const getVisiblePages = (): (number | string)[] => {
    const delta = 2; // Show 2 pages before and after current
    const range: number[] = [];
    const rangeWithDots: (number | string)[] = [];

    // Calculate range around current page
    const start = Math.max(2, currentPage - delta);
    const end = Math.min(totalPages - 1, currentPage + delta);

    // Add pages in range
    for (let i = start; i <= end; i++) {
      range.push(i);
    }

    // Add first page
    rangeWithDots.push(1);

    // Add ellipsis or pages between first and range
    if (start > 2) {
      rangeWithDots.push('...');
    }

    // Add range pages
    rangeWithDots.push(...range);

    // Add ellipsis or pages between range and last
    if (end < totalPages - 1) {
      rangeWithDots.push('...');
    }

    // Add last page (if more than 1 page)
    if (totalPages > 1) {
      rangeWithDots.push(totalPages);
    }

    return rangeWithDots;
  };

  // Handle edge cases
  if (totalPages <= 1) return null;

  const visiblePages = getVisiblePages();

  return (
    <div className="flex flex-col sm:flex-row items-center justify-between gap-4 mt-6 px-4 py-3 bg-white dark:bg-slate-800 border-t border-slate-200 dark:border-slate-700 rounded-lg shadow-sm">
      {/* Results info */}
      <div className="text-sm text-slate-600 dark:text-slate-400">
        Showing <span className="font-medium">{startIndex}</span> to{' '}
        <span className="font-medium">{endIndex}</span> of{' '}
        <span className="font-medium">{totalItems}</span> results
      </div>

      {/* Pagination controls */}
      <div className="flex items-center gap-1">
        {/* Previous button */}
        <button
          onClick={() => onPageChange(currentPage - 1)}
          disabled={!canGoPrev}
          className="relative inline-flex items-center px-2 py-2 text-sm font-medium text-slate-500 bg-white border border-slate-300 rounded-l-md hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed dark:bg-slate-800 dark:border-slate-600 dark:text-slate-400 dark:hover:bg-slate-700 transition-colors duration-200"
          title="Previous page"
        >
          <ChevronLeft className="h-4 w-4" />
        </button>

        {/* Page numbers */}
        {visiblePages.map((page, index) => (
          <React.Fragment key={index}>
            {page === '...' ? (
              <span className="relative inline-flex items-center px-3 py-2 text-sm font-medium text-slate-700 bg-white border border-slate-300 dark:bg-slate-800 dark:border-slate-600 dark:text-slate-300 cursor-default">
                &hellip;
              </span>
            ) : (
              <button
                onClick={() => onPageChange(page as number)}
                className={`relative inline-flex items-center px-3 py-2 text-sm font-medium border transition-colors duration-200 ${
                  currentPage === page
                    ? 'z-10 bg-blue-50 border-blue-500 text-blue-600 dark:bg-blue-900 dark:border-blue-400 dark:text-blue-300'
                    : 'text-slate-500 bg-white border-slate-300 hover:bg-slate-50 dark:bg-slate-800 dark:border-slate-600 dark:text-slate-400 dark:hover:bg-slate-700'
                }`}
                title={`Go to page ${page}`}
              >
                {page}
              </button>
            )}
          </React.Fragment>
        ))}

        {/* Next button */}
        <button
          onClick={() => onPageChange(currentPage + 1)}
          disabled={!canGoNext}
          className="relative inline-flex items-center px-2 py-2 text-sm font-medium text-slate-500 bg-white border border-slate-300 rounded-r-md hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed dark:bg-slate-800 dark:border-slate-600 dark:text-slate-400 dark:hover:bg-slate-700 transition-colors duration-200"
          title="Next page"
        >
          <ChevronRight className="h-4 w-4" />
        </button>
      </div>
    </div>
  );
};

export default Pagination;
