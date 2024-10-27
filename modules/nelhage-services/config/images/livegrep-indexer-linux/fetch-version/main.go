package main

import (
	"cmp"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"regexp"
	"slices"
	"strconv"
)

func Unwrap[T any](v T, err error) T {
	if err != nil {
		panic(fmt.Sprintf("unwrap(): %s", err.Error()))
	}
	return v
}

type TagResponse struct {
	// https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-repository-tags
	Name   string `json:"name"`
	Commit struct {
		Sha string `json:"sha"`
		Url string `json:"url"`
	} `json:"commit"`
}

type Tag struct {
	Major int
	Minor int
	Patch int
}

func CmpTag(l, r Tag) int {
	if v := cmp.Compare(l.Major, r.Major); v != 0 {
		return v
	}
	if v := cmp.Compare(l.Minor, r.Minor); v != 0 {
		return v
	}
	if v := cmp.Compare(l.Patch, r.Patch); v != 0 {
		return v
	}
	return 0
}

func atoi(s string) int {
	if s == "" {
		return -1
	}
	return Unwrap(strconv.Atoi(s))
}

func fetchTags(path string) (io.ReadCloser, error) {
	if path != "" {
		return os.Open(path)
	}

	req := Unwrap(http.NewRequest("GET", "https://api.github.com/repos/torvalds/linux/tags", nil))
	req.Header.Add("Accept", "application/vnd.github+json")
	req.Header.Add("X-GitHub-Api-Version", "2022-11-28")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("GET tags: %w", err)
	}
	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("GET tags: status=%s", resp.StatusCode)
	}
	return resp.Body, nil
}

func main() {
	var (
		verbose bool
		tagFile string
	)

	flag.BoolVar(&verbose, "v", false, "verbose")
	flag.StringVar(&tagFile, "read-tags", "", "Path to a tags.json override")
	flag.Parse()

	tagSrc := Unwrap(fetchTags(tagFile))
	defer tagSrc.Close()

	var parsed []TagResponse
	decoder := json.NewDecoder(tagSrc)
	if err := decoder.Decode(&parsed); err != nil {
		log.Fatalf("Decode: %s", err.Error())
	}

	if verbose {
		log.Printf("Found %d tags", len(parsed))
	}

	pat := regexp.MustCompile(`^v(?P<major>\d+)[.](?P<minor>\d+)(?:[.](?P<patch>\d+))?$`)
	ix_major := pat.SubexpIndex("major")
	ix_minor := pat.SubexpIndex("minor")
	ix_patch := pat.SubexpIndex("patch")

	var tags []Tag

	for _, p := range parsed {
		m := pat.FindStringSubmatch(p.Name)
		if verbose {
			log.Printf("Tag %q: ok=%v", p.Name, m != nil)
		}
		if m == nil {
			continue
		}
		tags = append(tags, Tag{
			atoi(m[ix_major]),
			atoi(m[ix_minor]),
			atoi(m[ix_patch]),
		})
	}

	slices.SortFunc(tags, CmpTag)
	latest := tags[len(tags)-1]
	fmt.Printf("%d.%d\n", latest.Major, latest.Minor)
}
