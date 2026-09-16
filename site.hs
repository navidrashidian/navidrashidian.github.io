--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Data.List (stripPrefix)
import           Hakyll


--------------------------------------------------------------------------------
config :: Configuration
config = defaultConfiguration
  { destinationDirectory = "docs"
  }

root :: String
root = "navidrashidian.github.io"

main :: IO ()
main = hakyllWith config $ do
    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler
    
    match (fromList ["misc.rst", "research.rst"]) $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= withItemBody (return . demoteTopLevelHeadings)
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

    {- match (fromList ["about.rst", "contact.markdown"]) $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls
    -}

    match "posts/*" $ do
        route $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    create ["archive.html"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let archiveCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Archives"            `mappend`
                    defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls


    match "index.html" $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let indexCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Home"                `mappend`
                    defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/home.html" indexCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateCompiler

    match "pdfs/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    create ["sitemap.xml"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"

            singlePages <- loadAll (fromList ["misc.rst", "research.rst"])

            let pages = posts <> singlePages
                sitemapCtx =
                    constField "root" root     <>
                    listField "pages" postCtx (return pages)
            makeItem ""
                >>= loadAndApplyTemplate "templates/sitemap.xml" sitemapCtx

--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
    constField "root" root       `mappend`
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext

demoteTopLevelHeadings :: String -> String
demoteTopLevelHeadings =
    replace "</h1>" "</h2>" . replace "<h1" "<h2"

replace :: String -> String -> String -> String
replace old new = go
  where
    go [] = []
    go input@(character : rest) =
        case stripPrefix old input of
            Just remaining -> new ++ go remaining
            Nothing        -> character : go rest
